using Microsoft.EntityFrameworkCore;
using SquadMatch.Domain.Models;

namespace SquadMatch.Infrastructure.Data;

public class SquadMatchDbContext : DbContext
{
    public SquadMatchDbContext(DbContextOptions<SquadMatchDbContext> options) : base(options)
    {
    }

    public DbSet<Room> Rooms => Set<Room>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Option> Options => Set<Option>();
    public DbSet<Vote> Votes => Set<Vote>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Impedire a un utente di votare due volte la stessa carta
        modelBuilder.Entity<Vote>()
            .HasIndex(v => new { v.UserId, v.OptionId })
            .IsUnique();

        modelBuilder.Entity<Room>()
            .HasMany(r => r.Users)
            .WithOne(u => u.Room)
            .HasForeignKey(u => u.RoomId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Room>()
            .HasMany(r => r.Options)
            .WithOne(o => o.Room)
            .HasForeignKey(o => o.RoomId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Room>()
            .HasMany(r => r.Votes)
            .WithOne(v => v.Room)
            .HasForeignKey(v => v.RoomId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
