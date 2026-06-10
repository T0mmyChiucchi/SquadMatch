SquadMatch

SquadMatch is a real-time multiplayer application designed to help groups of friends make decisions effortlessly. Say goodbye to the endless "Where should we eat?" or "What movie should we watch?" debates. SquadMatch gamifies group decision-making through a fun, Tinder-style swiping interface.

🎮 How It Works

- Create a Room: The host creates a room and selects a decision category (e.g., Restaurants, Movies). The app generates a unique 5-letter Join Code.
- Gather the Squad: Friends join the room using the code, picking an avatar and a nickname. The lobby updates in real-time as players connect.
- Swipe to Decide: Once the host starts the game, players are presented with a deck of cards representing their options. Swipe Right (Heart) for "Yes" and Left (Cross) for "No".
- The Big Reveal: The match engine waits for all players to finish voting. It then applies the room's Quorum Rule (either Unanimity or Majority) to declare the ultimate winner.
- Play Again: The results screen displays the winner and voting statistics. The host can instantly restart the game, seamlessly bringing everyone back to the lobby for another round.

🏗️ Architecture & Tech Stack

SquadMatch is a modern full-stack application demonstrating real-time bidirectional communication and robust architectural patterns.

Frontend

- Framework: Flutter (Optimized for Web & Mobile)
- Routing: go_router for seamless navigation flows.
- Real-Time Client: signalr_netcore to maintain a persistent WebSockets connection across screens.
- Design: Vanilla UI with smooth card-swiping animations and dynamic waiting screens.

Backend

- Framework: .NET 10 (ASP.NET Core Web API)
- Real-Time Server: SignalR Hubs for instant state broadcasting (joining, starting games, restarting).
- Architecture: Clean Architecture / CQRS pattern (using MediatR) to strictly separate Domain logic, Application commands, and Infrastructure.
- Database: SQLite via Entity Framework Core for lightweight, relational persistence of Rooms, Users, Options, and Votes.

💡 Key Features

- Real-Time State Sync: Lobby connections, game starts, and restarts are perfectly synchronized across all connected clients via SignalR groups.
- Smart Match Engine: Evaluates votes based on configurable quorum rules (Unanimity or Majority) only when all expected votes are securely cast.
- Persistent Connections: The SignalR connection remains alive across screen transitions, preventing ghost drop-offs.
- Responsive Web UI: Built with Flutter Web, delivering an app-like experience directly in the browser.
