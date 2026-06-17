using System.Net.Http.Headers;
using System.Text.Json;
using Microsoft.Extensions.Options;
using SquadMatch.Application.Interfaces;
using SquadMatch.Domain.Enums;
using SquadMatch.Domain.Models;
using SquadMatch.Infrastructure.Configuration;

namespace SquadMatch.Infrastructure.Services;

public class ApiOptionProvider : IOptionProvider
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ApiSettings _apiSettings;
    private readonly MockOptionProvider _mockProvider;

    public ApiOptionProvider(IHttpClientFactory httpClientFactory, IOptions<ApiSettings> apiSettings)
    {
        _httpClientFactory = httpClientFactory;
        _apiSettings = apiSettings.Value;
        _mockProvider = new MockOptionProvider();
    }

    public async Task<List<Option>> GetOptionsForCategoryAsync(RoomCategory category, Guid roomId, double? latitude = null, double? longitude = null, string? filterQuery = null)
    {
        return category switch
        {
            RoomCategory.Food => await FetchYelpOptionsAsync(roomId, latitude, longitude, filterQuery),
            RoomCategory.Movies => await FetchTmdbOptionsAsync(roomId, filterQuery),
            RoomCategory.Games => await FetchRawgOptionsAsync(roomId, filterQuery),
            _ => await _mockProvider.GetOptionsForCategoryAsync(category, roomId, latitude, longitude, filterQuery)
        };
    }

    private async Task<List<Option>> FetchYelpOptionsAsync(Guid roomId, double? latitude, double? longitude, string? filterQuery)
    {
        if (string.IsNullOrEmpty(_apiSettings.YelpApiKey))
            return await _mockProvider.GetOptionsForCategoryAsync(RoomCategory.Food, roomId, latitude, longitude);

        var client = _httpClientFactory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _apiSettings.YelpApiKey);

        // Fallback to New York coordinates if not provided (just to have results)
        double lat = latitude ?? 40.7128;
        double lon = longitude ?? -74.0060;
        
        string term = string.IsNullOrEmpty(filterQuery) ? "" : $"&term={Uri.EscapeDataString(filterQuery)}";

        string url = $"https://api.yelp.com/v3/businesses/search?latitude={lat}&longitude={lon}&categories=restaurants&limit=10{term}";
        var response = await client.GetAsync(url);

        if (!response.IsSuccessStatusCode)
            return await _mockProvider.GetOptionsForCategoryAsync(RoomCategory.Food, roomId, latitude, longitude);

        var content = await response.Content.ReadAsStringAsync();
        using var json = JsonDocument.Parse(content);
        var businesses = json.RootElement.GetProperty("businesses").EnumerateArray();

        var options = new List<Option>();
        foreach (var business in businesses)
        {
            options.Add(new Option
            {
                Id = Guid.NewGuid(),
                RoomId = roomId,
                Title = business.GetProperty("name").GetString() ?? "Unknown Restaurant",
                ImageUrl = business.TryGetProperty("image_url", out var img) ? img.GetString() ?? "" : "",
                Description = $"Rating: {business.GetProperty("rating").GetDouble()} ⭐ - {business.GetProperty("location").GetProperty("address1").GetString()}"
            });
        }

        return options;
    }

    private async Task<List<Option>> FetchTmdbOptionsAsync(Guid roomId, string? filterQuery)
    {
        if (string.IsNullOrEmpty(_apiSettings.TmdbApiKey))
            return await _mockProvider.GetOptionsForCategoryAsync(RoomCategory.Movies, roomId, null, null, filterQuery);

        var client = _httpClientFactory.CreateClient();

        int randomPage = Random.Shared.Next(1, 51); // 1 to 50
        string genreFilter = string.IsNullOrEmpty(filterQuery) ? "" : $"&with_genres={filterQuery}";
        string url = $"https://api.themoviedb.org/3/discover/movie?language=it-IT&vote_count.gte=100{genreFilter}&page={randomPage}&api_key={_apiSettings.TmdbApiKey}";
        
        var response = await client.GetAsync(url);

        if (!response.IsSuccessStatusCode)
            return await _mockProvider.GetOptionsForCategoryAsync(RoomCategory.Movies, roomId);

        var content = await response.Content.ReadAsStringAsync();
        using var json = JsonDocument.Parse(content);
        var results = json.RootElement.GetProperty("results").EnumerateArray().Take(10);

        var options = new List<Option>();
        foreach (var movie in results)
        {
            var posterPath = movie.GetProperty("poster_path").GetString();
            var imageUrl = !string.IsNullOrEmpty(posterPath) ? $"https://image.tmdb.org/t/p/w500{posterPath}" : "https://via.placeholder.com/400x500";

            options.Add(new Option
            {
                Id = Guid.NewGuid(),
                RoomId = roomId,
                Title = movie.GetProperty("title").GetString() ?? "Unknown Movie",
                ImageUrl = imageUrl,
                Description = movie.GetProperty("overview").GetString() ?? ""
            });
        }

        return options;
    }

    private async Task<List<Option>> FetchRawgOptionsAsync(Guid roomId, string? filterQuery)
    {
        if (string.IsNullOrEmpty(_apiSettings.RawgApiKey))
            return await _mockProvider.GetOptionsForCategoryAsync(RoomCategory.Games, roomId, null, null, filterQuery);

        var client = _httpClientFactory.CreateClient();
        
        int randomPage = Random.Shared.Next(1, 101); // 1 to 100
        string genreFilter = string.IsNullOrEmpty(filterQuery) ? "" : $"&genres={filterQuery}";
        string url = $"https://api.rawg.io/api/games?key={_apiSettings.RawgApiKey}&ordering=-rating&page_size=10&page={randomPage}{genreFilter}";
        var response = await client.GetAsync(url);

        if (!response.IsSuccessStatusCode)
            return await _mockProvider.GetOptionsForCategoryAsync(RoomCategory.Games, roomId);

        var content = await response.Content.ReadAsStringAsync();
        using var json = JsonDocument.Parse(content);
        var results = json.RootElement.GetProperty("results").EnumerateArray();

        var options = new List<Option>();
        foreach (var game in results)
        {
            var genres = string.Join(", ", game.GetProperty("genres").EnumerateArray().Select(g => g.GetProperty("name").GetString()));
            options.Add(new Option
            {
                Id = Guid.NewGuid(),
                RoomId = roomId,
                Title = game.GetProperty("name").GetString() ?? "Unknown Game",
                ImageUrl = game.TryGetProperty("background_image", out var img) ? img.GetString() ?? "" : "",
                Description = $"Genres: {genres}\nReleased: {game.GetProperty("released").GetString()}"
            });
        }

        return options;
    }
}
