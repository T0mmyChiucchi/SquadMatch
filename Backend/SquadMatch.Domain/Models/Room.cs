using SquadMatch.Domain.Enums;

namespace SquadMatch.Domain.Models;

public class Room
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string JoinCode { get; set; } = string.Empty;
    public RoomCategory Category { get; set; }
    public RoomStatus Status { get; set; } = RoomStatus.Open;
    public QuorumRule QuorumRule { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public List<User> Users { get; set; } = new();
    public List<Option> Options { get; set; } = new();
    public List<Vote> Votes { get; set; } = new();
}
