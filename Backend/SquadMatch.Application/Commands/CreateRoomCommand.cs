using MediatR;
using SquadMatch.Domain.Enums;
using SquadMatch.Domain.Models;

namespace SquadMatch.Application.Commands;

public record CreateRoomCommand(
    RoomCategory Category,
    QuorumRule QuorumRule,
    string HostNickname,
    Guid HostUserId,
    string HostAvatarUrl) : IRequest<Room>;
