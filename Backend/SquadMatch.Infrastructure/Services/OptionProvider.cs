using SquadMatch.Domain.Enums;
using SquadMatch.Domain.Models;
using SquadMatch.Application.Interfaces;

namespace SquadMatch.Infrastructure.Services;

public class MockOptionProvider : IOptionProvider
{
    private static readonly Dictionary<RoomCategory, List<(string Title, string ImageUrl, string Description)>> _mockData = new()
    {
        { RoomCategory.Food, new() {
            ("Pizzeria Da Michele", "https://picsum.photos/seed/pizza/400/500", "Autentica pizza napoletana."),
            ("Sushi Koko", "https://picsum.photos/seed/sushi/400/500", "All you can eat di altissima qualità."),
            ("Burger Joint", "https://picsum.photos/seed/burger/400/500", "Hamburger artigianali e patatine fritte."),
            ("El Camino Tacos", "https://picsum.photos/seed/tacos/400/500", "Tacos messicani autentici."),
            ("Vegan Paradise", "https://picsum.photos/seed/vegan/400/500", "Piatti 100% plant-based.")
        }},
        { RoomCategory.Movies, new() {
            ("Inception", "https://picsum.photos/seed/inception/400/500", "Un ladro ruba i segreti dal subconscio durante il sonno."),
            ("Interstellar", "https://picsum.photos/seed/interstellar/400/500", "Viaggio attraverso un wormhole per salvare l'umanità."),
            ("The Matrix", "https://picsum.photos/seed/matrix/400/500", "Un hacker scopre la vera natura della sua realtà."),
            ("Pulp Fiction", "https://picsum.photos/seed/pulp/400/500", "Intreccio di storie nel mondo criminale di Los Angeles.")
        }},
        { RoomCategory.Games, new() {
            ("Elden Ring", "https://picsum.photos/seed/elden/400/500", "Esplora l'Interregno in questo capolavoro FromSoftware."),
            ("Mario Kart 8", "https://picsum.photos/seed/mario/400/500", "Corse arcade frenetiche per tutta la famiglia."),
            ("Among Us", "https://picsum.photos/seed/amongus/400/500", "Trova l'impostore prima che uccida l'equipaggio."),
            ("Overcooked! 2", "https://picsum.photos/seed/overcooked/400/500", "Cucina in condizioni estreme con i tuoi amici.")
        }}
    };

    public Task<List<Option>> GetOptionsForCategoryAsync(RoomCategory category, Guid roomId, double? latitude = null, double? longitude = null, string? filterQuery = null)
    {
        if (!_mockData.TryGetValue(category, out var items))
        {
            return Task.FromResult(new List<Option>());
        }

        var options = items.Select(item => new Option
        {
            Id = Guid.NewGuid(),
            RoomId = roomId,
            Title = item.Title,
            ImageUrl = item.ImageUrl,
            Description = item.Description
        }).ToList();

        return Task.FromResult(options);
    }
}
