using MediatR;
using Microsoft.AspNetCore.SignalR;
using SquadMatch.Application.Commands;

using Microsoft.EntityFrameworkCore;
using SquadMatch.Domain.Models;
using SquadMatch.Infrastructure.Data;

namespace SquadMatch.Api.Hubs;

public class RoomHub : Hub
{
    private readonly IMediator _mediator;
    private readonly SquadMatchDbContext _dbContext;

    public RoomHub(IMediator mediator, SquadMatchDbContext dbContext)
    {
        _mediator = mediator;
        _dbContext = dbContext;
    }

    public async Task JoinRoom(string joinCode, string nickname, Guid userId, string avatarUrl)
    {
        Console.WriteLine($"[RoomHub] JoinRoom CHIAMATO da {nickname} - JoinCode: {joinCode}, UserId: {userId}");
        try
        {
            var room = await _dbContext.Rooms.FirstOrDefaultAsync(r => r.JoinCode == joinCode);
            if (room == null)
            {
                throw new HubException("Room not found");
            }

            var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null)
            {
                Console.WriteLine($"[RoomHub] Utente {nickname} non trovato nel DB, lo sto aggiungendo...");
                _dbContext.Users.Add(new User { Id = userId, RoomId = room.Id, Nickname = nickname, AvatarUrl = avatarUrl, IsHost = false });
                await _dbContext.SaveChangesAsync();
                Console.WriteLine($"[RoomHub] Utente {nickname} aggiunto con successo.");
            }
            else
            {
                Console.WriteLine($"[RoomHub] Utente {nickname} ({userId}) GIA' PRESENTE nel DB. Aggiorno Avatar.");
                user.RoomId = room.Id;
                user.AvatarUrl = avatarUrl;
                user.Nickname = nickname;
                await _dbContext.SaveChangesAsync();
            }

            await Groups.AddToGroupAsync(Context.ConnectionId, joinCode);
            await Clients.Group(joinCode).SendAsync("UserJoined", new { Nickname = nickname, AvatarUrl = avatarUrl });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[SIGNALR ERROR in JoinRoom] {ex.Message}");
            throw;
        }
    }

    public async Task StartGame(string joinCode)
    {
        try
        {
            var room = await _dbContext.Rooms.FirstOrDefaultAsync(r => r.JoinCode == joinCode);
            if (room != null && room.Status == SquadMatch.Domain.Enums.RoomStatus.Open)
            {
                room.Status = SquadMatch.Domain.Enums.RoomStatus.Voting;
                await _dbContext.SaveChangesAsync();
                await Clients.Group(joinCode).SendAsync("OnGameStarted");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[SIGNALR ERROR in StartGame] {ex.Message}");
            throw;
        }
    }

    public async Task CastVote(string joinCode, Guid userId, Guid optionId, bool isPositive)
    {
        try
        {
            var command = new SubmitVoteCommand(joinCode, userId, optionId, isPositive);
            var isMatch = await _mediator.Send(command);

            // Se MediatR ci restituisce true, significa che questo voto ha fatto scattare il quorum!
            if (isMatch)
            {
                await Clients.Group(joinCode).SendAsync("OnMatchFound", optionId);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[SIGNALR ERROR in CastVote] {ex.Message}");
            Console.WriteLine(ex.StackTrace);
            if (ex.InnerException != null)
            {
                Console.WriteLine($"Inner Exception: {ex.InnerException.Message}");
            }
            throw; // Rilancia per SignalR
        }
    }

    public async Task RestartGame(string joinCode)
    {
        try
        {
            var room = await _dbContext.Rooms.Include(r => r.Votes).FirstOrDefaultAsync(r => r.JoinCode == joinCode);
            if (room != null)
            {
                _dbContext.Votes.RemoveRange(room.Votes);
                room.Status = SquadMatch.Domain.Enums.RoomStatus.Open;
                await _dbContext.SaveChangesAsync();
                
                await Clients.Group(joinCode).SendAsync("OnGameRestarted");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[SIGNALR ERROR in RestartGame] {ex.Message}");
            throw;
        }
    }
}
