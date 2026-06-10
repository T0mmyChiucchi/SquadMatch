namespace SquadMatch.Domain.Models;

public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid RoomId { get; set; }
    public Room? Room { get; set; }
    public string Nickname { get; set; } = string.Empty;
    public string AvatarUrl { get; set; } = string.Empty;
    public bool IsHost { get; set; }
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
}
