## Разбор структуры и логики проекта

### User:
```
Зайди на гитхаб этого проекта https://github.com/madmatvey/gasfree_sdk и изучи его.

Ответь на следующие вопросы:
1. где какие части кода находятся 
2. за что эти части кода отвечают 
3. какие есть ключевые зависимости и структура проекта
4. Про что этот проект, что это такое?
```

### ChatGPT:
```
Вот подробный разбор проекта gasfree_sdk — Ruby SDK от madmatvey/madmatvey (Eugene Leontev) для обеспечения gas‑free транзакций в сети Tron:

1. Где какие части кода находятся (структура репозитория) 🗂️
Основные каталоги:

lib/ — исходники гема.
lib/gasfree_sdk.rb — главный файл, подключающий всё.
lib/gasfree_sdk/ — поддиректории с модулями:
client.rb — HTTP‑клиент API.
models/ — модели данных: Token, Provider, TransferRequest, TransferStatus и т.п.
tron_eip712_signer.rb — EIP‑712/TIP‑712 криптографические методы для Tron.
base58.rb — утилиты работы с Tron‑адресами.
examples/ — примеры использования: отправка транзакций, подписи.
spec/ — тесты (через rake spec).
bin/ — скрипты для настройки, консоли и релиза.

2. За что отвечают эти части кода
GasfreeSdk.configure — устанавливает ключ api_key, api_secret и endpoint.

GasfreeSdk.client — основной объект для API-вызовов:

.tokens — список поддерживаемых токенов TRC‑20.
.providers — провайдеры услуги газ‑фри.
.address("T...") — информация об аккаунте (nonce, frozen assets).
.submit_transfer(request) — отправка транзакции с подписью.
.transfer_status(id) — мониторинг состояния.

TronEIP712Signer — сборка и подпись структурированных данных по EIP‑712/TIP‑712 с Keccak256 и Base58:
sign_typed_data_{testnet,mainnet} — готовые подписи.
Хелперы: keccac256, hash_struct, encode_type, и др.
Base58 — кодировка/декодировка адресов Tron.
Models — строгие структуры (через dry‑struct, dry‑types): валидация данных, преобразование ответа API.

3. Ключевые зависимости и структура проекта
Зависимости (указаны в gemspec) 
libraries.io
+8
socket.dev
+8
x.com
+8
:

dry‑configurable / struct / types / validation — конфигурация, модели, валидация.
faraday + faraday-retry — HTTP‑клиент с возможностью повторных попыток.
eth — Ethereum‑ориентированные утилиты (Keccak, ABI‑энкодинг).
rbsecp256k1 — подпись secp256k1 для EIP‑712.
Структура:

markdown
Копировать
Редактировать
lib/
├── gasfree_sdk.rb
└── gasfree_sdk/
    ├── client.rb
    ├── tron_eip712_signer.rb
    ├── base58.rb
    └── models/
        ├── token.rb
        ├── provider.rb
        ├── transfer_request.rb
        └── transfer_status.rb
4. Про что этот проект, что это такое?
gasfree_sdk — это Ruby SDK для GasFree.io, сервиса, позволяющего пользователям отправлять TRC‑20 токены (например USDT‑TRON) без необходимости наличия TRX и энергии (energy) на своём аккаунте. Проект решает UX‑проблему Tron‑блокчейна: пользователю не нужны собственные ресурсы для оплаты транзакции — SDK генерирует EIP‑712 подпись, отправляет запрос на сервер GasFree, который уже выполняет и оплачивает сами on‑chain транзакции 
socket.dev
.

Главный кейс:

Ruby‑приложение вызывает .tokens, .providers, формирует TransferRequest.
Подписывает типизированное сообщение через TronEIP712Signer.
Отсылает в GasFree API, который хостит провайдер транзакцию в Tron‑сеть, оплачивая её сам.
Таким образом, SDK облегчает разработчикам интеграцию gas‑free механики в dApp‑приложения на Ruby.




```

### User:
```
Хоршо.
В проекте есть список Проблем (Issues), нуждающиеся в решении на этой странице https://github.com/madmatvey/gasfree_sdk/issues.

Я выбрал следующую проблему "Decimal Precision Mismatch".
The SDK does not verify that amount respects the token's decimals.
Risk: Users may lose funds by supplying incorrect integer amounts (e.g., sending 1 USDT as 1 instead of 1_000_000).
Proposed fix: Fetch or accept token decimal metadata and validate/convert amounts accordingly.


Сформулируй plan-of-action / decomposition — что нужно сделать, чтобы решить эту задачу. 
```

### ChatGPT:
```
Вот подробный plan-of-action / decomposition для решения задачи "Decimal Precision Mismatch" в проекте gasfree_sdk:

🔧 Проблема
SDK не учитывает количество знаков после запятой (decimals) у токена при передаче суммы.
Пример ошибки: пользователь хочет отправить 1 USDT, но указывает 1, тогда как правильное значение — 1_000_000 (USDT имеет decimals: 6).

✅ Цель
Защитить пользователя от потерь из-за неправильного указания количества токенов.

Учитывать метаданные токенов (decimals) при передаче значений.

Предоставить API, принимающее "человеческий" формат (1.5 USDT) и преобразующее в integer.

🧩 План действий (decomposition)
1. Добавить поле decimals в модель Token
Файл: lib/gasfree_sdk/models/token.rb

Убедиться, что GasfreeSdk.client.tokens возвращает это поле (API его отдаёт? проверить по JSON).

Обновить Token < Dry::Struct:

ruby
Копировать
Редактировать
attribute :decimals, Types::Coercible::Integer
2. Создать утилиту для нормализации суммы
Новый модуль: lib/gasfree_sdk/utils/amount_converter.rb
Методы:

ruby
Копировать
Редактировать
def self.to_base_units(amount, decimals)
  (BigDecimal(amount.to_s) * (10 ** decimals)).to_i
end

def self.from_base_units(integer_amount, decimals)
  BigDecimal(integer_amount) / (10 ** decimals)
end
3. Обновить создание TransferRequest
Файл: lib/gasfree_sdk/models/transfer_request.rb

Добавить валидацию:

если пользователь передал человеческую сумму — нужно преобразовать с учётом decimals.

если пользователь передаёт уже integer — сделать флаг raw_amount, или выдать предупреждение.

Пример обработки:

ruby
Копировать
Редактировать
def self.build_with_token(token:, human_amount:, **args)
  base_amount = AmountConverter.to_base_units(human_amount, token.decimals)
  new(amount: base_amount, token_address: token.address, **args)
end
4. Обновить пример в examples/transfer.rb
Покажи, как использовать новую функциональность:

ruby
Копировать
Редактировать
token = client.tokens.find { |t| t.symbol == "USDT" }
request = TransferRequest.build_with_token(
  token: token,
  human_amount: 1.5,
  from_address: "...",
  to_address: "...",
  ...
)
5. Написать тесты
Файл: spec/lib/gasfree_sdk/utils/amount_converter_spec.rb

Проверить правильность to_base_units и from_base_units:

ruby
Копировать
Редактировать
expect(AmountConverter.to_base_units(1.5, 6)).to eq(1_500_000)
Файл: spec/lib/gasfree_sdk/models/transfer_request_spec.rb

Убедиться, что build_with_token правильно преобразует сумму.

Протестировать ошибочные случаи: nil, отрицательные, неверный формат.

6. (Опционально) Добавить авто-проверку при инициализации TransferRequest
Если известен токен и amount передан как float — автоматически преобразовывать и/или выдавать ошибку.

🧪 Итог
✅ Добавлено поле decimals у токена

✅ Созданы утилиты to_base_units и from_base_units

✅ Обновлён механизм создания запроса

✅ Обновлены примеры

✅ Добавлены тесты
```
