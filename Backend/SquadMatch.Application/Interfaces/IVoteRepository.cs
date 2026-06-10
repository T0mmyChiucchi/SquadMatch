using SquadMatch.Domain.Models;

namespace SquadMatch.Application.Interfaces;

public interface IVoteRepository
{
    Task AddAsync(Vote vote, CancellationToken cancellationToken = default);
    Task SaveChangesAsync(CancellationToken cancellationToken = default);
}
