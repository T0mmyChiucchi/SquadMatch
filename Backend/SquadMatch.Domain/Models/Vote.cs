namespace SquadMatch.Domain.Models;

public class Vote
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid RoomId { get; set; }
    public Room? Room { get; set; }
    
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public Guid OptionId { get; set; }
    public Option? Option { get; set; }

    public bool IsPositive { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
