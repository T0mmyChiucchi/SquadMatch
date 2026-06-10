using MediatR;
using SquadMatch.Domain.Models;
using SquadMatch.Application.Interfaces;

namespace SquadMatch.Application.Queries;

public record GetRoomOptionsQuery(string JoinCode) : IRequest<List<Option>>;

public class GetRoomOptionsQueryHandler : IRequestHandler<GetRoomOptionsQuery, List<Option>>
{
    private readonly IRoomRepository _roomRepository;

    public GetRoomOptionsQueryHandler(IRoomRepository roomRepository)
    {
        _roomRepository = roomRepository;
    }

    public async Task<List<Option>> Handle(GetRoomOptionsQuery request, CancellationToken cancellationToken)
    {
        var room = await _roomRepository.GetByJoinCodeWithDetailsAsync(request.JoinCode, cancellationToken);
        
        if (room == null)
            return new List<Option>();

        return room.Options;
    }
}
