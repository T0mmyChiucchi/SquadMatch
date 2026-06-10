namespace SquadMatch.Domain.Models;

public class Option
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid RoomId { get; set; }
    public Room? Room { get; set; }
    public string ExternalApiId { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string ImageUrl { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}
