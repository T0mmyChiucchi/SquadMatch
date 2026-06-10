using SquadMatch.Domain.Enums;
using SquadMatch.Domain.Models;

namespace SquadMatch.Application.Interfaces;

public interface IOptionProvider
{
    Task<List<Option>> GetOptionsForCategoryAsync(RoomCategory category, Guid roomId);
}
