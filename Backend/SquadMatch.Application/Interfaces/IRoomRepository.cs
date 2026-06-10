using SquadMatch.Domain.Models;

namespace SquadMatch.Application.Interfaces;

public interface IRoomRepository
{
    Task<Room?> GetByIdWithDetailsAsync(Guid id, CancellationToken cancellationToken = default);
    Task<Room?> GetByJoinCodeWithDetailsAsync(string joinCode, CancellationToken cancellationToken = default);
    Task<User?> GetUserByIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task AddAsync(Room room, CancellationToken cancellationToken = default);
    Task SaveChangesAsync(CancellationToken cancellationToken = default);
}
