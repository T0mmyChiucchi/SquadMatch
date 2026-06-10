using Microsoft.EntityFrameworkCore;
using SquadMatch.Application.Interfaces;
using SquadMatch.Domain.Models;
using SquadMatch.Infrastructure.Data;

namespace SquadMatch.Infrastructure.Repositories;

public class RoomRepository : IRoomRepository
{
    private readonly SquadMatchDbContext _dbContext;

    public RoomRepository(SquadMatchDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task AddAsync(Room room, CancellationToken cancellationToken = default)
    {
        _dbContext.Rooms.Add(room);
        await Task.CompletedTask;
    }

    public async Task<Room?> GetByIdWithDetailsAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _dbContext.Rooms
            .Include(r => r.Users)
            .Include(r => r.Votes)
            .Include(r => r.Options)
            .FirstOrDefaultAsync(r => r.Id == id, cancellationToken);
    }

    public async Task<Room?> GetByJoinCodeWithDetailsAsync(string joinCode, CancellationToken cancellationToken = default)
    {
        return await _dbContext.Rooms
            .Include(r => r.Users)
            .Include(r => r.Votes)
            .Include(r => r.Options)
            .FirstOrDefaultAsync(r => r.JoinCode == joinCode, cancellationToken);
    }

    public async Task SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<User?> GetUserByIdAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);
    }
}
