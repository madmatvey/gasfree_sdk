token = client.tokens.find { |t| t.symbol == "USDT" }
request = TransferRequest.build_with_token(
  token: token,
  human_amount: 1.5,
  from_address: "...",
  to_address: "...",
  ...
)