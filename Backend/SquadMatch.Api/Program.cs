using Microsoft.EntityFrameworkCore;
using SquadMatch.Application.Commands;
using SquadMatch.Api.Hubs;
using SquadMatch.Infrastructure.Data;
using SquadMatch.Infrastructure.Repositories;
using SquadMatch.Infrastructure.Configuration;

using SquadMatch.Application.Interfaces;
using SquadMatch.Infrastructure.Services;
using SquadMatch.Domain.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", b => b.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
});

builder.Services.ConfigureHttpJsonOptions(options => {
    options.SerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
    options.SerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
});

builder.Services.AddSignalR();

builder.Services.AddDbContext<SquadMatchDbContext>(options =>
    options.UseSqlite("Data Source=SquadMatch.db"));

builder.Services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(CreateRoomCommand).Assembly));

builder.Services.AddScoped<MatchEngine>();
builder.Services.AddScoped<IRoomRepository, RoomRepository>();
builder.Services.AddScoped<IVoteRepository, VoteRepository>();

builder.Services.Configure<ApiSettings>(builder.Configuration.GetSection("ApiSettings"));
builder.Services.AddHttpClient();
builder.Services.AddScoped<IOptionProvider, ApiOptionProvider>();

var app = builder.Build();

app.UseCors("AllowAll");
app.MapHub<RoomHub>("/roomHub");

app.MapPost("/api/rooms", async (CreateRoomCommand command, MediatR.IMediator mediator) =>
{
    var room = await mediator.Send(command);
    return Results.Ok(room);
});

app.MapGet("/api/rooms/{joinCode}", async (string joinCode, IRoomRepository repo) =>
{
    var room = await repo.GetByJoinCodeWithDetailsAsync(joinCode);
    if (room == null) return Results.NotFound();
    
    return Results.Ok(new {
        room.JoinCode,
        Status = room.Status.ToString(),
        Users = room.Users.Select(u => new { u.Nickname, u.AvatarUrl, u.IsHost }).ToList()
    });
});

app.MapGet("/api/rooms/{joinCode}/options", async (string joinCode, MediatR.IMediator mediator) =>
{
    var query = new SquadMatch.Application.Queries.GetRoomOptionsQuery(joinCode);
    var options = await mediator.Send(query);
    if (options == null || options.Count == 0) return Results.NotFound();
    return Results.Ok(options);
});

app.MapGet("/api/rooms/{joinCode}/results", async (string joinCode, IRoomRepository repo, MatchEngine matchEngine) =>
{
    var room = await repo.GetByJoinCodeWithDetailsAsync(joinCode);
    if (room == null) return Results.NotFound();

    var winnerId = matchEngine.CheckForMatch(room);
    var winnerOption = room.Options.FirstOrDefault(o => o.Id == winnerId);

    var stats = room.Options.Select(o => new {
        OptionId = o.Id,
        Name = o.Title,
        ImageUrl = o.ImageUrl,
        PositiveVotes = room.Votes.Count(v => v.OptionId == o.Id && v.IsPositive),
        NegativeVotes = room.Votes.Count(v => v.OptionId == o.Id && !v.IsPositive)
    }).OrderByDescending(s => s.PositiveVotes).ToList();

    return Results.Ok(new {
        Winner = winnerOption != null ? new { winnerOption.Id, Name = winnerOption.Title, winnerOption.ImageUrl } : null,
        Statistics = stats
    });
});

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<SquadMatchDbContext>();
    db.Database.EnsureCreated();
}

app.Run();
