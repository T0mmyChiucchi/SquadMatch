using MediatR;
using SquadMatch.Application.Interfaces;
using SquadMatch.Domain.Models;
using SquadMatch.Domain.Services;

namespace SquadMatch.Application.Commands;

public class SubmitVoteCommandHandler : IRequestHandler<SubmitVoteCommand, bool>
{
    private readonly IRoomRepository _roomRepository;
    private readonly IVoteRepository _voteRepository;
    private readonly MatchEngine _matchEngine;

    public SubmitVoteCommandHandler(IRoomRepository roomRepository, IVoteRepository voteRepository, MatchEngine matchEngine)
    {
        _roomRepository = roomRepository;
        _voteRepository = voteRepository;
        _matchEngine = matchEngine;
    }

    public async Task<bool> Handle(SubmitVoteCommand request, CancellationToken cancellationToken)
    {
        var room = await _roomRepository.GetByJoinCodeWithDetailsAsync(request.JoinCode, cancellationToken);
        if (room == null) return false;

        // Se la stanza è già chiusa, non accettiamo altri voti
        if (room.Status != SquadMatch.Domain.Enums.RoomStatus.Open && room.Status != SquadMatch.Domain.Enums.RoomStatus.Voting)
        {
            var existingWinner = _matchEngine.CheckForMatch(room);
            return existingWinner.HasValue;
        }

        // Se l'utente ha già votato per questa opzione, ignoriamo il duplicato
        if (room.Votes.Any(v => v.UserId == request.UserId && v.OptionId == request.OptionId))
        {
            var existingWinner = _matchEngine.CheckForMatch(room);
            return existingWinner.HasValue;
        }

        var vote = new Vote
        {
            RoomId = room.Id, // Usiamo l'ID interno
            UserId = request.UserId,
            OptionId = request.OptionId,
            IsPositive = request.IsPositive
        };

        await _voteRepository.AddAsync(vote, cancellationToken);
        await _voteRepository.SaveChangesAsync(cancellationToken);

        // Riaggiorniamo la room dal db per avere la lista dei voti aggiornata
        room = await _roomRepository.GetByIdWithDetailsAsync(room.Id, cancellationToken);
        if (room == null) return false;

        var winnerOptionId = _matchEngine.CheckForMatch(room);

        if (winnerOptionId.HasValue && (room.Status == SquadMatch.Domain.Enums.RoomStatus.Open || room.Status == SquadMatch.Domain.Enums.RoomStatus.Voting))
        {
            room.Status = SquadMatch.Domain.Enums.RoomStatus.Matched;
            await _roomRepository.SaveChangesAsync(cancellationToken);
        }

        return winnerOptionId.HasValue;
    }
}
