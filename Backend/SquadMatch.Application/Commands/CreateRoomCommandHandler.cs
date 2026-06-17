using MediatR;
using SquadMatch.Application.Interfaces;
using SquadMatch.Domain.Models;

namespace SquadMatch.Application.Commands;

public class CreateRoomCommandHandler : IRequestHandler<CreateRoomCommand, Room>
{
    private readonly IRoomRepository _roomRepository;
    private readonly IOptionProvider _optionProvider;

    public CreateRoomCommandHandler(IRoomRepository roomRepository, IOptionProvider optionProvider)
    {
        _roomRepository = roomRepository;
        _optionProvider = optionProvider;
    }

    public async Task<Room> Handle(CreateRoomCommand request, CancellationToken cancellationToken)
    {
        var room = new Room
        {
            Category = request.Category,
            QuorumRule = request.QuorumRule,
            JoinCode = GenerateJoinCode()
        };

        var existingUser = await _roomRepository.GetUserByIdAsync(request.HostUserId, cancellationToken);
        User hostUser;
        if (existingUser != null)
        {
            hostUser = existingUser;
            hostUser.Room = room;
            hostUser.Nickname = request.HostNickname;
            hostUser.AvatarUrl = request.HostAvatarUrl;
            hostUser.IsHost = true;
            hostUser.JoinedAt = DateTime.UtcNow;
        }
        else
        {
            hostUser = new User
            {
                Id = request.HostUserId,
                Room = room,
                Nickname = request.HostNickname,
                AvatarUrl = request.HostAvatarUrl,
                IsHost = true
            };
        }

        room.Users.Add(hostUser);

        // Genera le opzioni e salvale nel DB per evitare FK constraint errors sui voti successivi
        var options = await _optionProvider.GetOptionsForCategoryAsync(request.Category, room.Id, request.Latitude, request.Longitude, request.FilterQuery);
        room.Options = options;

        await _roomRepository.AddAsync(room, cancellationToken);
        await _roomRepository.SaveChangesAsync(cancellationToken);

        return room;
    }

    private static string GenerateJoinCode(int length = 5)
    {
        const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        return new string(Enumerable.Repeat(chars, length)
            .Select(s => s[Random.Shared.Next(s.Length)]).ToArray());
    }
}
