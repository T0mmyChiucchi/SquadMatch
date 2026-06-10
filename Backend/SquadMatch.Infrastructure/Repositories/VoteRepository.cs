using SquadMatch.Application.Interfaces;
using SquadMatch.Domain.Models;
using SquadMatch.Infrastructure.Data;

namespace SquadMatch.Infrastructure.Repositories;

public class VoteRepository : IVoteRepository
{
    private readonly SquadMatchDbContext _dbContext;

    public VoteRepository(SquadMatchDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task AddAsync(Vote vote, CancellationToken cancellationToken = default)
    {
        _dbContext.Votes.Add(vote);
        await Task.CompletedTask;
    }

    public async Task SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        await _dbContext.SaveChangesAsync(cancellationToken);
    }
}
