using SquadMatch.Domain.Enums;
using SquadMatch.Domain.Models;

namespace SquadMatch.Domain.Services;

public class MatchEngine
{
    /// <summary>
    /// Verifica se c'è un match nella stanza in base ai voti e alla regola di quorum impostata.
    /// Restituisce l'OptionId vincitrice, o null se non c'è un match.
    /// </summary>
    public Guid? CheckForMatch(Room room)
    {
        if (!room.Users.Any() || !room.Options.Any()) return null;

        var totalUsers = room.Users.Count;
        var totalOptions = room.Options.Count;
        var expectedVotes = totalUsers * totalOptions;

        Console.WriteLine($"[MatchEngine] Verifica Match per Room {room.Id}. TotalUsers: {totalUsers}, TotalOptions: {totalOptions}, ExpectedVotes: {expectedVotes}, CurrentVotes: {room.Votes.Count}");

        // Attendiamo che TUTTI abbiano votato TUTTE le opzioni
        if (room.Votes.Count < expectedVotes)
        {
            return null;
        }

        var positiveVotesByOption = room.Votes
            .Where(v => v.IsPositive)
            .GroupBy(v => v.OptionId)
            .Select(g => new { OptionId = g.Key, Count = g.Count() })
            .ToList();

        var validMatches = new List<Guid>();

        foreach (var voteGroup in positiveVotesByOption)
        {
            bool isMatch = room.QuorumRule switch
            {
                QuorumRule.Unanimity => voteGroup.Count >= totalUsers,
                QuorumRule.Majority => voteGroup.Count > (totalUsers / 2),
                _ => false
            };

            if (isMatch)
            {
                validMatches.Add(voteGroup.OptionId);
            }
        }

        if (validMatches.Any())
        {
            // Se ci sono più vincitori, scegliamo quello con più voti positivi.
            // Dato che abbiamo filtrato per quorum, se è Unanimità avranno tutti lo stesso numero di voti,
            // quindi prendiamo il primo. Se Maggioranza, prendiamo il più alto.
            var winner = positiveVotesByOption
                .Where(v => validMatches.Contains(v.OptionId))
                .OrderByDescending(v => v.Count)
                .First();
                
            return winner.OptionId;
        }

        // Segnaliamo esplicitamente che il gioco è finito ma non c'è vincitore.
        // Guid.Empty per dire "Nessun vincitore". Il front-end si aspetta 'null' per dire nessun vincitore?
        // Se ritorniamo Guid.Empty, OnMatchFound riceverà Guid.Empty e il client chiederà i risultati.
        // Nei risultati, _winner sarà null se non lo trova.
        return Guid.Empty;
    }
}
