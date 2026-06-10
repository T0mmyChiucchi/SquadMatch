using Microsoft.AspNetCore.SignalR.Client;

class Program {
    static async Task Main() {
        var hubConnection = new HubConnectionBuilder()
            .WithUrl("http://localhost:5138/roomHub")
            .Build();
        
        await hubConnection.StartAsync();
        
        var roomId = Guid.Parse("6c47f4e8-c0d1-403f-94ca-1cd2dff4db54");
        var userId = Guid.NewGuid();
        
        await hubConnection.InvokeAsync("JoinRoom", roomId, "Guest", userId);
        Console.WriteLine("JoinRoom done.");
        
        var optionId = Guid.Parse("e105e36d-0b31-4bb9-bb0e-562daa30535d");
        await hubConnection.InvokeAsync("CastVote", roomId, userId, optionId, true);
        Console.WriteLine("CastVote done.");
    }
}
