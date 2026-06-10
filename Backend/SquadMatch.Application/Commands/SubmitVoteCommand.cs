using MediatR;
using SquadMatch.Domain.Models;

namespace SquadMatch.Application.Commands;

public record SubmitVoteCommand(string JoinCode, Guid UserId, Guid OptionId, bool IsPositive) : IRequest<bool>;
