# Unity Networking - Multiplayer Development

Comprehensive guide for building multiplayer games with Unity Netcode for GameObjects.

## Unity Netcode for GameObjects (Official Solution)

**Why Netcode for GameObjects?**
- Official Unity solution (first-party support)
- Server-authoritative by design
- Built-in lag compensation
- Optimized for performance
- Best for LAN and online multiplayer

## Setup

### 1. Install Netcode Package

```
Window → Package Manager → Unity Registry → "Netcode for GameObjects" → Install
```

### 2. NetworkManager Setup

```csharp
// Add to a GameObject in scene
NetworkManager networkManager = gameObject.AddComponent<NetworkManager>();
networkManager.NetworkConfig = new NetworkConfig {
    ProtocolType = UnityTransport.ProtocolType.UnityTransport
};
```

### 3. Unity Transport (for LAN/Online)

```csharp
var transport = gameObject.AddComponent<UnityTransport>();
transport.SetConnectionData(
    "127.0.0.1",  // Server IP (localhost for testing, LAN IP for LAN)
    7777          // Port
);
```

## Server-Authoritative Architecture

**Critical Principle**: Server has final authority on all game state.

**Client Request → Server Validates → Server Updates → Broadcast to Clients**

### Example: Player Movement

```csharp
public class PlayerController : NetworkBehaviour
{
    [SerializeField] private float moveSpeed = 5f;
    private Rigidbody2D rb;

    void Update() {
        if (!IsOwner) return; // Only owner can send input

        // Read input on client
        Vector2 input = new Vector2(
            Input.GetAxis("Horizontal"),
            Input.GetAxis("Vertical")
        );

        // Send to server for validation
        MoveServerRpc(input);
    }

    [ServerRpc]
    void MoveServerRpc(Vector2 input) {
        // Server validates and applies movement
        rb.velocity = input.normalized * moveSpeed;
    }
}
```

## NetworkVariables (State Synchronization)

**Use for**: Health, ammo, money, scores - anything that changes during gameplay.

```csharp
public class Player : NetworkBehaviour
{
    // Automatically synchronized from server to all clients
    public NetworkVariable<int> Health = new NetworkVariable<int>(
        100,
        NetworkVariableReadPermission.Everyone,
        NetworkVariableWritePermission.Server // Only server can write
    );

    public NetworkVariable<int> Money = new NetworkVariable<int>(800);

    public override void OnNetworkSpawn() {
        if (IsClient) {
            // Subscribe to changes on clients
            Health.OnValueChanged += OnHealthChanged;
        }
    }

    void OnHealthChanged(int oldValue, int newValue) {
        Debug.Log($"Health changed: {oldValue} → {newValue}");
        UpdateHealthUI(newValue);
    }

    [ServerRpc]
    public void TakeDamageServerRpc(int damage) {
        // Only server modifies NetworkVariables
        Health.Value -= damage;
        if (Health.Value <= 0) {
            Die();
        }
    }
}
```

## RPCs (Remote Procedure Calls)

### ServerRpc (Client → Server)

Client sends request to server:

```csharp
[ServerRpc]
void PurchaseWeaponServerRpc(int weaponId) {
    // Runs on server
    WeaponData weapon = GetWeaponData(weaponId);

    // Validate transaction
    if (Money.Value >= weapon.price) {
        Money.Value -= weapon.price;
        GiveWeapon(weaponId);
    } else {
        // Deny purchase
        PurchaseDeniedClientRpc("Insufficient funds");
    }
}
```

### ClientRpc (Server → Clients)

Server sends update to all clients:

```csharp
[ClientRpc]
void PurchaseDeniedClientRpc(string reason) {
    // Runs on all clients
    ShowErrorMessage(reason);
}
```

### Targeted ClientRpc (Server → Specific Client)

```csharp
[ClientRpc]
void NotifyClientRpc(string message, ClientRpcParams clientRpcParams = default) {
    // Runs only on specified client
    ShowNotification(message);
}

// Call with target:
var clientParams = new ClientRpcParams {
    Send = new ClientRpcSendParams {
        TargetClientIds = new ulong[] { targetClientId }
    }
};
NotifyClientRpc("You killed an enemy!", clientParams);
```

## LAN Multiplayer Setup

### Host/Join Pattern

```csharp
public class NetworkUI : MonoBehaviour
{
    private NetworkManager networkManager;

    void Start() {
        networkManager = NetworkManager.Singleton;
    }

    public void StartHost() {
        // Acts as both server and client
        networkManager.StartHost();
    }

    public void StartClient() {
        // Connect to host on LAN
        networkManager.StartClient();
    }

    public void Shutdown() {
        networkManager.Shutdown();
    }
}
```

### LAN Discovery (Find Servers on Local Network)

```csharp
using System.Net;
using System.Net.Sockets;

public class LANDiscovery : MonoBehaviour
{
    private UdpClient udpClient;
    private const int discoveryPort = 47777;

    // Server: Broadcast presence
    public void BroadcastServer() {
        udpClient = new UdpClient();
        byte[] data = Encoding.UTF8.GetBytes("CS2D_SERVER");
        IPEndPoint endPoint = new IPEndPoint(IPAddress.Broadcast, discoveryPort);
        udpClient.Send(data, data.Length, endPoint);
    }

    // Client: Listen for servers
    public void FindServers(Action<string> onServerFound) {
        udpClient = new UdpClient(discoveryPort);
        IPEndPoint remoteEP = new IPEndPoint(IPAddress.Any, discoveryPort);

        udpClient.BeginReceive((result) => {
            byte[] data = udpClient.EndReceive(result, ref remoteEP);
            string message = Encoding.UTF8.GetString(data);
            if (message == "CS2D_SERVER") {
                onServerFound(remoteEP.Address.ToString());
            }
        }, null);
    }
}
```

## Client-Side Prediction + Server Reconciliation

For responsive gameplay despite network latency:

```csharp
public class PredictedPlayerController : NetworkBehaviour
{
    private Vector2 serverPosition;
    private Vector2 clientPosition;
    private Queue<InputState> inputHistory = new Queue<InputState>();

    struct InputState {
        public int tick;
        public Vector2 input;
    }

    void Update() {
        if (!IsOwner) return;

        Vector2 input = GetInput();

        // Client-side prediction: Apply movement immediately
        clientPosition += input * moveSpeed * Time.deltaTime;
        transform.position = clientPosition;

        // Store input history for reconciliation
        inputHistory.Enqueue(new InputState {
            tick = currentTick,
            input = input
        });

        // Send to server
        SendInputServerRpc(currentTick, input);
    }

    [ServerRpc]
    void SendInputServerRpc(int tick, Vector2 input) {
        // Server applies movement
        serverPosition += input * moveSpeed * Time.deltaTime;

        // Send authoritative position back
        ReconcileClientRpc(tick, serverPosition);
    }

    [ClientRpc]
    void ReconcileClientRpc(int tick, Vector2 authoritativePosition) {
        if (!IsOwner) {
            // Other clients just accept server position
            transform.position = authoritativePosition;
            return;
        }

        // Owner reconciles: replay inputs after server tick
        serverPosition = authoritativePosition;

        // Remove old inputs
        while (inputHistory.Count > 0 && inputHistory.Peek().tick <= tick) {
            inputHistory.Dequeue();
        }

        // Replay remaining inputs
        Vector2 replayPosition = serverPosition;
        foreach (var state in inputHistory) {
            replayPosition += state.input * moveSpeed * Time.deltaTime;
        }

        // Snap if too far off
        if (Vector2.Distance(clientPosition, replayPosition) > 0.5f) {
            clientPosition = replayPosition;
            transform.position = clientPosition;
        }
    }
}
```

## Network Tick Rate

```csharp
// Set in NetworkManager
NetworkManager.Singleton.NetworkConfig.TickRate = 64; // 64 ticks/sec (CS:GO standard)
```

Higher tick rate = smoother sync, more bandwidth.
- **30 Hz**: Casual games, mobile
- **60 Hz**: Competitive games, good responsiveness
- **64 Hz**: CS:GO standard, excellent for shooters
- **128 Hz**: Competitive esports (high bandwidth)

## Spawn Management

```csharp
public class NetworkSpawnManager : NetworkBehaviour
{
    [SerializeField] private GameObject playerPrefab;
    [SerializeField] private Transform[] spawnPoints;

    public override void OnNetworkSpawn() {
        if (IsServer) {
            NetworkManager.Singleton.OnClientConnectedCallback += OnClientConnected;
        }
    }

    void OnClientConnected(ulong clientId) {
        // Spawn player for new client
        Transform spawnPoint = GetRandomSpawnPoint();
        GameObject player = Instantiate(playerPrefab, spawnPoint.position, Quaternion.identity);
        player.GetComponent<NetworkObject>().SpawnAsPlayerObject(clientId);
    }
}
```

## Anti-Cheat (Server Validation)

```csharp
[ServerRpc]
void FireWeaponServerRpc(Vector2 aimDirection) {
    // Validate fire rate (prevent rapid fire hacks)
    float timeSinceLastShot = Time.time - lastShotTime;
    if (timeSinceLastShot < weaponData.fireRate) {
        return; // Too fast, reject
    }

    // Validate ammo (prevent infinite ammo)
    if (currentAmmo <= 0) {
        return; // No ammo, reject
    }

    // Server performs raycast (prevent aim hacks)
    RaycastHit2D hit = Physics2D.Raycast(transform.position, aimDirection, weaponData.range);

    if (hit.collider != null) {
        var enemy = hit.collider.GetComponent<Player>();
        if (enemy != null) {
            enemy.TakeDamageServerRpc(weaponData.damage);
        }
    }

    currentAmmo--;
    lastShotTime = Time.time;
}
```

## Bandwidth Optimization

```csharp
// Only sync what's needed
public NetworkVariable<int> Health = new NetworkVariable<int>(); // 4 bytes

// Avoid syncing every frame
private float syncTimer = 0f;
void Update() {
    syncTimer += Time.deltaTime;
    if (syncTimer >= 0.1f) { // Sync every 100ms instead of 16ms
        SyncPositionServerRpc(transform.position);
        syncTimer = 0f;
    }
}

// Use smaller data types
[ServerRpc]
void SyncHealthServerRpc(byte health) { // byte (0-255) instead of int
    Health.Value = health;
}
```

## Connection Quality Handling

```csharp
public class NetworkStats : MonoBehaviour
{
    void Update() {
        if (NetworkManager.Singleton.IsConnectedClient) {
            var transport = NetworkManager.Singleton.NetworkConfig.NetworkTransport;

            // RTT (Round-Trip Time)
            ulong rtt = transport.GetCurrentRtt(NetworkManager.Singleton.LocalClientId);
            Debug.Log($"Ping: {rtt}ms");

            // Packet loss
            if (rtt > 200) {
                ShowLagWarning();
            }
        }
    }
}
```

## Common Patterns

### Damage System (Server-Authoritative)

```csharp
[ServerRpc(RequireOwnership = false)]
public void TakeDamageServerRpc(int damage, ulong attackerId) {
    Health.Value -= damage;

    if (Health.Value <= 0) {
        DieServerRpc(attackerId);
    }
}

[ServerRpc]
void DieServerRpc(ulong killerId) {
    // Award kill to attacker
    var killer = NetworkManager.Singleton.ConnectedClients[killerId].PlayerObject;
    killer.GetComponent<Player>().Kills.Value++;

    // Respawn this player after delay
    StartCoroutine(RespawnAfterDelay(3f));
}
```

### Round System

```csharp
public class RoundManager : NetworkBehaviour
{
    public NetworkVariable<RoundState> CurrentState = new NetworkVariable<RoundState>();
    public NetworkVariable<float> RoundTime = new NetworkVariable<float>();

    [ServerRpc]
    public void StartRoundServerRpc() {
        CurrentState.Value = RoundState.BuyPhase;
        RoundTime.Value = 15f; // 15 sec buy phase

        StartCoroutine(RoundTimer());
    }

    IEnumerator RoundTimer() {
        while (RoundTime.Value > 0) {
            yield return new WaitForSeconds(1f);
            RoundTime.Value--;
        }

        if (CurrentState.Value == RoundState.BuyPhase) {
            CurrentState.Value = RoundState.Combat;
            RoundTime.Value = 120f; // 2 min combat
        }
    }
}
```

---

**For CS2D LAN game specifically, use Host/Join pattern with LAN discovery for local network server browsing.**
