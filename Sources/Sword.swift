import Foundation

public class Sword {

  let token: String

  let requester: Request
  let endpoints = Endpoints()
  var shards: [Shard] = []
  let eventer = Eventer()

  var gatewayUrl: String?
  var shardCount: Int?

  public var guilds: [String: Guild] = [:]
  public var unavailableGuilds: [String: UnavailableGuild] = [:]
  public var user: User?

  public init(token: String) {
    self.token = token
    self.requester = Request(token)
  }

  public func on(_ eventName: String, _ completion: @escaping (_ data: Any) -> Void) {
    self.eventer.on(eventName, completion)
  }

  public func emit(_ eventName: String, with data: Any...) {
    self.eventer.emit(eventName, with: data)
  }

  func getGateway(completion: @escaping (Error?, [String: Any]?) -> Void) {
    self.requester.request(self.endpoints.gateway, authorization: true) { error, data in
      if error != nil {
        completion(error, nil)
        return
      }

      guard let data = data as? [String: Any] else {
        completion(.unknown, nil)
        return
      }

      completion(nil, data)
    }
  }

  public func connect() {
    self.getGateway() { error, data in
      if error != nil {
        print(error!)
        sleep(2)
        self.connect()
      }else {
        self.gatewayUrl = "\(data!["url"]!)/?encoding=json&v=6"
        self.shardCount = data!["shards"] as? Int

        for id in 0..<self.shardCount! {
          let shard = Shard(self, id, self.shardCount!)
          self.shards.append(shard)
          shard.startWS(self.gatewayUrl!)
        }

      }
    }
  }

  public func editStatus(to status: String = "online", playing game: [String: Any]? = nil) {
    guard self.shards.count > 0 else { return }
    var data: [String: Any] = ["afk": status == "idle", "game": NSNull(), "since": status == "idle" ? Date().milliseconds : 0, "status": status]

    if game != nil {
      data["game"] = game
    }

    let payload = Payload(op: .statusUpdate, data: data).encode()

    for shard in self.shards {
      shard.send(payload, presence: true)
    }
  }

  public func getChannel(_ channelId: String, _ completion: @escaping (Error?, Any?) -> Void) {

  }

  public func send(_ content: String, to channelId: String) {
    self.send(content, to: channelId, {error, data in})
  }

  public func send(_ content: String, to channelId: String, _ completion: @escaping (Error?, Any?) -> Void) {
    let data = ["content": content].createBody()
    self.requester.request(endpoints.createMessage(channelId), body: data, authorization: true, method: "POST", rateLimited: true, completion: completion)
  }

  public func setUsername(to name: String) {
    self.setUsername(to: name, {user in})
  }

  public func setUsername(to name: String, _ completion: (_ data: User) -> Void) {

  }

}
