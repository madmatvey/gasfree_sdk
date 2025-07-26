## Partial API Response Handling #19

# Models use attribute? for optional fields, but unexpected missing data raises Dry::Struct::Error.

Risk: SDK crashes when API evolves or partially fails.

Proposed fix: Provide default values or graceful fallback parsing for optional fields.

# Ощушения от работы с Cursor  
Это был интересный опыт, мне как начинающему разработчику были понятны пояснения AI и очень понравилось, что были выставлены акценты и предложены пути решения. В процессе работы опробовал новый инструмент который планирую использовать в будущем. 
Ниже предоставлен лог запросов и ответов от AI.

_Exported on 7/25/2025 at 23:12:12 GMT+3 from Cursor (1.2.4)_

---

**User**

Определи где какие части кода находятся в данном проекте

---

**Cursor**

Вот обзор структуры проекта gasfree_sdk и где находятся основные части кода:

### 1. Основная библиотека (исходный код)
- **lib/gasfree_sdk/** — основная папка с исходным кодом библиотеки.
  - **base58.rb, crypto.rb, time_parser.rb, tron_eip712_signer.rb, types.rb** — отдельные модули с реализациями различных функций (например, криптография, парсинг времени, работа с Tron и т.д.).
  - **client.rb** — вероятно, основной клиент для взаимодействия с API или сервисом.
  - **errors.rb** — определение ошибок/исключений.
  - **log_sanitizer.rb, sanitized_logs_middleware.rb** — обработка и фильтрация логов.
  - **models/** — модели данных:
    - **gas_free_address.rb, provider.rb, token.rb, transfer_request.rb, transfer_response.rb** — классы, описывающие структуры данных (адреса, токены, запросы/ответы на перевод и т.д.).
  - **utils/amount_converter.rb** — утилиты для конвертации сумм.
  - **version.rb** — версия библиотеки.
  - **models.rb** — возможно, объединяет все модели.
- **lib/gasfree_sdk.rb** — точка входа, обычно подключает все остальные файлы.

### 2. Примеры использования
- **examples/** — примеры использования библиотеки (скрипты на Ruby, демонстрирующие разные сценарии).

### 3. Тесты
- **spec/** — тесты (RSpec):
  - **gasfree_sdk/** — тесты для отдельных компонентов библиотеки.
  - **lib/gasfree_sdk/models/** — тесты для моделей.
  - **lib/gasfree_sdk/utils/** — тесты для утилит.
  - **examples/** — тесты для примеров.
  - **fixtures/vcr_cassettes/** — фикстуры для VCR (записи HTTP-запросов).
  - **spec_helper.rb** — конфигурация тестов.

### 4. Конфигурация и метаданные
- **gasfree_sdk.gemspec** — описание гемa (RubyGem).
- **Gemfile, Gemfile.lock** — зависимости проекта.
- **Rakefile** — задачи Rake (например, запуск тестов).
- **README.md, LICENSE.txt, CHANGELOG.md** — документация, лицензия, история изменений.

### 5. Скрипты
- **bin/** — исполняемые скрипты для консоли или установки.

### 6. Типы (RBS)
- **sig/gasfree_sdk.rbs** — сигнатуры типов для Ruby (RBS).

### 7. Документация по задачам/issue
- **issue*.md, Issue*.md** — заметки и обсуждения по задачам/issue.

---

Если нужна детализация по какому-то конкретному файлу или модулю — уточните, и я расскажу подробнее!

---

**User**

Опиши за что эти части кода отвечают 

---

**Cursor**

Конечно! Вот описание ответственности основных частей кода в проекте gasfree_sdk:

---

### 1. **lib/gasfree_sdk/** — Исходный код библиотеки

- **base58.rb**  
  Реализация алгоритма кодирования/декодирования Base58 (часто используется для адресов в блокчейне).

- **client.rb**  
  Основной клиент для взаимодействия с внешним API или сервисом GasFree. Здесь реализованы методы для отправки запросов, получения данных и т.д.

- **crypto.rb**  
  Криптографические функции: подпись, хеширование, генерация ключей и т.п.

- **errors.rb**  
  Определение собственных классов ошибок/исключений, которые используются в библиотеке для обработки нештатных ситуаций.

- **log_sanitizer.rb, sanitized_logs_middleware.rb**  
  Модули для фильтрации и "очистки" логов, чтобы скрывать чувствительные данные или приводить логи к единому формату.

- **models/**  
  Классы-модели, описывающие основные сущности:
  - **gas_free_address.rb** — структура для адреса GasFree.
  - **provider.rb** — описание провайдера (например, блокчейн-провайдера).
  - **token.rb** — структура токена (например, ERC20).
  - **transfer_request.rb** — структура запроса на перевод.
  - **transfer_response.rb** — структура ответа на перевод.

- **models.rb**  
  Обычно агрегирует все модели из папки models для удобного импорта.

- **time_parser.rb**  
  Функции для парсинга и обработки времени/дат.

- **tron_eip712_signer.rb**  
  Реализация подписания данных по стандарту EIP-712 для блокчейна Tron.

- **types.rb**  
  Определения типов данных, используемых в библиотеке.

- **utils/amount_converter.rb**  
  Утилиты для конвертации сумм (например, перевод из wei в ether и обратно).

- **version.rb**  
  Хранит текущую версию библиотеки.

---

### 2. **lib/gasfree_sdk.rb**  
Точка входа в библиотеку. Обычно подключает все остальные файлы и модули, чтобы пользователь мог просто `require 'gasfree_sdk'`.

---

### 3. **examples/**  
Примеры использования библиотеки для разных сценариев (отправка токенов, базовое использование, работа с пустыми ключами и т.д.).

---

### 4. **spec/**  
Тесты на RSpec:
- **gasfree_sdk/** — тесты для основных компонентов библиотеки.
- **lib/gasfree_sdk/models/** — тесты для моделей.
- **lib/gasfree_sdk/utils/** — тесты для утилит.
- **examples/** — тесты для примеров.
- **fixtures/vcr_cassettes/** — записи HTTP-запросов для тестирования без реального обращения к API.
- **spec_helper.rb** — конфигурация тестовой среды.

---

### 5. **bin/**  
Исполняемые скрипты для запуска из консоли (например, для настройки или тестирования библиотеки).

---

### 6. **sig/gasfree_sdk.rbs**  
Файл с описанием типов (RBS) для статической проверки типов в Ruby.

---

### 7. **Конфигурация и документация**
- **gasfree_sdk.gemspec** — описание гемa (имя, версия, зависимости, файлы и т.д.).
- **Gemfile, Gemfile.lock** — список зависимостей и их версии.
- **Rakefile** — задачи для автоматизации (например, запуск тестов).
- **README.md** — основная документация по использованию библиотеки.
- **LICENSE.txt** — лицензия.
- **CHANGELOG.md** — история изменений.
- **issue*.md, Issue*.md** — заметки и обсуждения по задачам/issue.

---

Если нужно подробнее по какому-то файлу или интересует конкретная логика — уточните, расскажу детальнее!

---

**User**

How I can solve this problem? 
Give me plan-of-action

Models use attribute? for optional fields, but unexpected missing data raises Dry::Struct::Error.

Risk: SDK crashes when API evolves or partially fails.

Proposed fix: Provide default values or graceful fallback parsing for optional fields.

---

**Cursor**

Great summary of the problem! Here’s a clear plan-of-action to make your SDK models more robust against missing optional fields, so that missing data does not crash your app.

---

## Plan of Action

### 1. **Audit All Models for Optional Fields**
- Identify all models (likely subclasses of `Dry::Struct`) that have optional fields (those using `attribute?`).

### 2. **Set Default Values for Optional Fields**
- For each optional field, provide a sensible default value using the `default:` option in `attribute?`.
  - Example:  
    ```ruby
    attribute? :foo, Types::String.optional.default('') 
    ```
- If a default is not appropriate, use `nil` as the default.

### 3. **Graceful Fallback in Parsing**
- Wrap model instantiation in a rescue block to catch `Dry::Struct::Error` and handle missing/invalid data gracefully.
- Optionally, implement a custom method (e.g., `safe_new`) that tries to instantiate the struct and fills in missing fields with defaults or logs a warning.

### 4. **Test with Incomplete Data**
- Write or update tests to ensure that models can be instantiated with missing optional fields and that no exceptions are raised.

### 5. **Document the Change**
- Update the README or internal docs to explain how missing fields are handled and what the defaults are.

---

## Example Implementation

**Before:**
```ruby
attribute? :foo, Types::String
```

**After:**
```ruby
attribute? :foo, Types::String.optional.default(nil)
```
or, for a default value:
```ruby
attribute? :foo, Types::String.optional.default('default_value')
```

**Graceful Instantiation:**
```ruby
def self.safe_new(attrs)
  new(attrs)
rescue Dry::Struct::Error => e
  # Log warning, fill missing keys with nil/default, and retry
end
```

---

## Summary Table

| Step | Action |
|------|--------|
| 1    | Audit all models for `attribute?` usage |
| 2    | Add `.default(...)` to all optional fields |
| 3    | Add safe instantiation logic if needed |
| 4    | Add/expand tests for missing data |
| 5    | Update documentation |

---

Would you like a code example for a specific model, or help with a script to automate the audit?

```ruby
    attribute? :foo, Types::String.optional.default('') 
```

```ruby
attribute? :foo, Types::String
```

```ruby
attribute? :foo, Types::String.optional.default(nil)
```

```ruby
attribute? :foo, Types::String.optional.default('default_value')
```

```ruby
def self.safe_new(attrs)
  new(attrs)
rescue Dry::Struct::Error => e
  # Log warning, fill missing keys with nil/default, and retry
end
```

---

**User**

Начни с аудита моделей

---

**Cursor**

Аудит моделей показал следующее:

### 1. Где используются опциональные поля (`attribute?`)
- **lib/gasfree_sdk/models/transfer_response.rb**  
  Здесь много полей объявлены как опциональные через `attribute?`, например:
  - `created_at`, `updated_at`, `account_address`, `gas_free_address`, `provider_address`, `target_address`, `token_address`, `amount`, `max_fee`, `signature`, `nonce`, `expired_at`, `state` и др.

### 2. Где все поля обязательные (`attribute`)
- **lib/gasfree_sdk/models/gas_free_address.rb**  
  Все поля обязательные (используется только `attribute`).
- **lib/gasfree_sdk/models/provider.rb**  
  Все поля обязательные.
- **lib/gasfree_sdk/models/token.rb**  
  Все поля обязательные.
- **lib/gasfree_sdk/models/transfer_request.rb**  
  Все поля обязательные.

---

### Вывод

- **Проблема с падением из-за отсутствующих данных** актуальна только для моделей, где используются `attribute?` (на данный момент — только `TransferResponse`).
- Остальные модели требуют наличия всех полей и не допускают их отсутствие.

---

**Следующий шаг:**  
Рассмотреть добавление дефолтных значений для опциональных полей в `TransferResponse` и/или внедрение безопасного парсинга для этой модели.

Если нужно, могу сразу показать, как добавить дефолты и реализовать безопасный парсинг для этой модели.

---

**User**

Опиши проблему максимально подробно

---

**Cursor**

Вот максимально подробное описание проблемы:

---

## Суть проблемы

В проекте используются модели на основе `Dry::Struct`, которые описывают структуры данных, приходящих из внешнего API (например, GasFree). Для некоторых моделей (например, `TransferResponse`) поля объявлены как опциональные с помощью `attribute?`. Это означает, что эти поля могут отсутствовать в данных, приходящих от API.

Однако, несмотря на то, что поле объявлено как опциональное, если в данных отсутствует это поле или оно имеет неожиданный тип, `Dry::Struct` по умолчанию выбрасывает исключение (`Dry::Struct::Error`). Это приводит к аварийному завершению работы SDK (crash), если структура данных изменилась на стороне API, либо если произошёл частичный сбой и не все данные были возвращены.

---

## Почему это опасно

1. **Хрупкость к изменениям API:**  
   Если API эволюционирует и убирает/переименовывает/делает необязательным какое-то поле, SDK начнёт выбрасывать исключения при попытке распарсить ответ, даже если это поле не критично для работы.

2. **Проблемы с частичными сбоями:**  
   Если API возвращает не все данные (например, из-за внутренних ошибок или деградации), SDK не сможет корректно обработать даже те данные, которые пришли, и полностью упадёт.

3. **Плохой пользовательский опыт:**  
   Вместо того чтобы вернуть частичный результат или хотя бы корректно обработать ошибку, SDK аварийно завершает работу, что может привести к потере данных, невозможности продолжить выполнение программы и другим негативным последствиям.

---

## Как проявляется

- В коде модели, например, `TransferResponse`, есть поля:
  ```ruby
  attribute? :created_at, Types::JSON::Time
  attribute? :account_address, Types::Address
  # и т.д.
  ```
- Если в ответе API отсутствует, например, `created_at`, то при попытке создать объект:
  ```ruby
  TransferResponse.new(api_response)
  ```
  будет выброшено исключение:
  ```
  Dry::Struct::Error: [TransferResponse.new] :created_at is missing in Hash input
  ```
- Аналогично, если тип не совпадает (например, пришёл `null` вместо строки), будет выброшено исключение о несоответствии типа.

---

## Причина

- По умолчанию, даже для опциональных полей, если не задано значение по умолчанию (`default:`), Dry::Struct требует, чтобы поле либо присутствовало, либо было явно передано как `nil` (если тип допускает `nil`).
- Если поле отсутствует и не задан дефолт, выбрасывается исключение.

---

## Риски

- **SDK становится нестабильным** при любых изменениях или ошибках на стороне API.
- **Пользователь не может обработать частичный результат** — всё выполнение прерывается исключением.
- **Трудно поддерживать SDK** при эволюции API.

---

## Итог

SDK должен быть устойчивым к отсутствию опциональных данных:  
- либо задавать дефолтные значения для опциональных полей,  
- либо реализовать безопасный парсинг с graceful fallback (например, логировать отсутствие поля, но не падать).

---

Если нужна иллюстрация с примером кода или стеком ошибки — могу добавить!

```ruby
  attribute? :created_at, Types::JSON::Time
  attribute? :account_address, Types::Address
  # и т.д.
```

```ruby
  TransferResponse.new(api_response)
```

```plaintext
  Dry::Struct::Error: [TransferResponse.new] :created_at is missing in Hash input
```

---

**User**

Предложи пути по декомпозиции данной задачи и её решения

---

**Cursor**

Вот варианты декомпозиции задачи и подходы к её решению:

---

## 1. **Аудит моделей**
- Найти все модели, использующие `Dry::Struct` и опциональные поля (`attribute?`).
- Зафиксировать, какие поля действительно могут отсутствовать и какие значения для них допустимы по умолчанию.

---

## 2. **Введение дефолтных значений**
- Для каждого опционального поля определить и явно указать дефолтное значение через `.default(...)`.
  - Для строк — `nil` или пустая строка.
  - Для чисел — `nil` или 0.
  - Для массивов — `[]`.
  - Для вложенных структур — `nil` или пустой объект.
- Протестировать, что создание объекта с отсутствующими полями не вызывает исключения.

---

## 3. **Реализация безопасного парсинга**
- Создать вспомогательный метод (например, `safe_new`), который:
  - Пытается создать объект Dry::Struct.
  - В случае ошибки — логирует проблему, подставляет дефолты и повторяет попытку.
- Внедрить этот метод во все места, где парсятся ответы API.

---

## 4. **Тестирование**
- Добавить/расширить тесты:
  - Проверить создание моделей с отсутствующими опциональными полями.
  - Проверить обработку неожиданных/невалидных данных.
  - Проверить, что SDK не падает, а возвращает максимально возможный результат.

---

## 5. **Документирование**
- Описать в README или внутренней документации:
  - Как SDK ведёт себя при отсутствии данных.
  - Какие дефолты используются.
  - Как обрабатываются ошибки парсинга.

---

## 6. **(Опционально) Вынести обработку в middleware**
- Если парсинг моделей происходит централизованно, можно реализовать middleware, который будет перехватывать ошибки Dry::Struct и применять fallback-логику.

---

## Пример декомпозиции в виде задач

1. **Аудит моделей и полей**  
   1.1. Составить список всех моделей с опциональными полями  
   1.2. Для каждого поля определить дефолт

2. **Рефакторинг моделей**  
   2.1. Добавить `.default(...)` для всех опциональных полей  
   2.2. Проверить совместимость с текущим кодом

3. **Безопасный парсинг**  
   3.1. Реализовать `safe_new`  
   3.2. Использовать его при парсинге ответов API

4. **Тесты**  
   4.1. Добавить тесты на отсутствие полей  
   4.2. Добавить тесты на невалидные значения

5. **Документация**  
   5.1. Описать изменения и поведение SDK

---

Если нужно — могу расписать пример кода для каждого этапа или предложить шаблон для задачи в трекере.

---

**User**

Определи дефолт для каждого поля

---

**Cursor**

Вот дефолты для каждого опционального поля в модели `TransferResponse` с пояснениями:

---

| Поле                    | Тип                | Предлагаемый дефолт | Обоснование/Комментарий                                 |
|-------------------------|--------------------|---------------------|---------------------------------------------------------|
| created_at              | Time (JSON::Time)  | nil                 | Время может отсутствовать, nil — стандартно             |
| updated_at              | Time (JSON::Time)  | nil                 | Аналогично                                             |
| account_address         | Address            | nil                 | Адрес может быть неизвестен                             |
| gas_free_address        | Address            | nil                 | Аналогично                                             |
| provider_address        | Address            | nil                 | Аналогично                                             |
| target_address          | Address            | nil                 | Аналогично                                             |
| token_address           | Address            | nil                 | Аналогично                                             |
| amount                  | JSON::Amount       | nil                 | Сумма может отсутствовать                               |
| max_fee                 | JSON::Amount       | nil                 | Аналогично                                             |
| signature               | String             | nil                 | Подпись может отсутствовать                             |
| nonce                   | Nonce (Integer)    | nil                 | Может отсутствовать                                     |
| expired_at              | Time (JSON::Time)  | nil                 | Может отсутствовать                                     |
| estimated_activate_fee  | JSON::Amount       | nil                 | Может отсутствовать                                     |
| estimated_transfer_fee  | JSON::Amount       | nil                 | Может отсутствовать                                     |
| txn_hash                | Hash (String)      | nil                 | Может отсутствовать                                     |
| txn_block_num           | Integer            | nil                 | Может отсутствовать                                     |
| txn_block_timestamp     | Integer            | nil                 | Может отсутствовать                                     |
| txn_state               | String             | nil                 | Может отсутствовать                                     |
| txn_activate_fee        | JSON::Amount       | nil                 | Может отсутствовать                                     |
| txn_transfer_fee        | JSON::Amount       | nil                 | Может отсутствовать                                     |
| txn_total_fee           | JSON::Amount       | nil                 | Может отсутствовать                                     |
| txn_amount              | JSON::Amount       | nil                 | Может отсутствовать                                     |
| txn_total_cost          | JSON::Amount       | nil                 | Может отсутствовать                                     |

---

**Принцип:**  
- Для всех опциональных полей, если нет явного бизнес-смысла подставлять другое значение, дефолт — `nil`.
- Если в будущем потребуется, можно для некоторых полей (например, массивов или строк) использовать пустые значения (`[]`, `""`), но для текущих типов `nil` — наиболее безопасно и прозрачно.

Если нужно — могу сразу подготовить патч для добавления этих дефолтов в модель!

---

**User**

Да, подготовь патч и проверь совместимость с кодом

---

**Cursor**

```ruby
// ... existing code ...
      attribute? :created_at, Types::JSON::Time.optional.default(nil)
      attribute? :updated_at, Types::JSON::Time.optional.default(nil)
      attribute? :account_address, Types::Address.optional.default(nil)
      attribute? :gas_free_address, Types::Address.optional.default(nil)
      attribute? :provider_address, Types::Address.optional.default(nil)
      attribute? :target_address, Types::Address.optional.default(nil)
      attribute? :token_address, Types::Address.optional.default(nil)
      attribute? :amount, Types::JSON::Amount.optional.default(nil)
      attribute? :max_fee, Types::JSON::Amount.optional.default(nil)
      attribute? :signature, Types::String.optional.default(nil)
      attribute? :nonce, Types::Nonce.optional.default(nil)
      attribute? :expired_at, Types::JSON::Time.optional.default(nil)
// ... existing code ...
      attribute? :estimated_activate_fee, Types::JSON::Amount.optional.default(nil)
      attribute? :estimated_transfer_fee, Types::JSON::Amount.optional.default(nil)
      attribute? :txn_hash, Types::Hash.optional.default(nil)
      attribute? :txn_block_num, Types::Integer.optional.default(nil)
      attribute? :txn_block_timestamp, Types::Integer.optional.default(nil)
      attribute? :txn_state, Types::String.constrained(
        included_in: %w[INIT NOT_ON_CHAIN ON_CHAIN SOLIDITY ON_CHAIN_FAILED]
      ).optional.default(nil)
      attribute? :txn_activate_fee, Types::JSON::Amount.optional.default(nil)
      attribute? :txn_transfer_fee, Types::JSON::Amount.optional.default(nil)
      attribute? :txn_total_fee, Types::JSON::Amount.optional.default(nil)
      attribute? :txn_amount, Types::JSON::Amount.optional.default(nil)
      attribute? :txn_total_cost, Types::JSON::Amount.optional.default(nil)
// ... existing code ...
```

Патч с дефолтами для всех опциональных полей в модели `TransferResponse` успешно применён.  
Я также запустил все тесты проекта — они прошли без единой ошибки.

**Вывод:**  
- Теперь отсутствие любого опционального поля в ответе API не приведёт к аварийному завершению работы SDK.
- Совместимость с существующим кодом и тестами полностью сохранена.

Если нужно внести аналогичные изменения в другие модели или требуется дополнительная документация — дайте знать!

---

**User**

Да, внеси изменения в другие модели и проверь совместимость 

---

**Cursor**

```ruby
// ... existing code ...
```

```ruby
// ... existing code ...
```

```ruby
// ... existing code ...
```

```ruby
// ... existing code ...
```

Во всех остальных моделях (`Asset`, `GasFreeAddress`, `ProviderConfig`, `Provider`, `Token`, `TransferRequest`) опциональных полей нет — все поля обязательные, поэтому изменений не потребовалось.

Я повторно запустил все тесты — они прошли успешно, совместимость полностью сохранена.

**Итог:**  
- Все модели проверены на наличие опциональных полей.
- Дефолты добавлены там, где это необходимо (только в `TransferResponse`).
- SDK теперь устойчив к отсутствию данных в опциональных полях, и все тесты проходят.

Если потребуется добавить новые опциональные поля в будущем — не забудьте сразу указывать дефолт!

---

**User**

Каковы следующие шаги по исправлению данной проблемы

---

**Cursor**

Вот рекомендуемые следующие шаги для полного и устойчивого решения проблемы с опциональными полями и эволюцией API:

---

## 1. **Документировать изменения**
- Обновить README или внутреннюю документацию:
  - Описать, что теперь опциональные поля в моделях безопасны к отсутствию в ответе API.
  - Указать, что для новых опциональных полей всегда нужно указывать дефолт через `.optional.default(nil)`.

---

## 2. **Внедрить практику для новых моделей**
- Ввести правило: при добавлении новых моделей или полей, если поле опциональное — обязательно указывать дефолт.
- Добавить это требование в code review checklist.

---

## 3. **Рассмотреть централизованную обработку ошибок парсинга**
- Если в будущем появятся более сложные случаи (например, вложенные структуры с опциональными полями), можно реализовать централизованный механизм безопасного парсинга (например, через вспомогательную функцию или middleware).
- Это позволит логировать и обрабатывать любые неожиданные ошибки при парсинге данных из API.

---

## 4. **Добавить тесты на эволюцию API**
- Добавить тесты, которые моделируют ситуацию, когда в ответе API отсутствуют опциональные поля или появляются новые неизвестные поля.
- Проверить, что SDK не падает и корректно обрабатывает такие случаи.

---

## 5. **Мониторинг и обратная связь**
- Если SDK используется в продакшене, добавить мониторинг на появление новых ошибок парсинга или неожиданных данных.
- Быстро реагировать на обратную связь от пользователей SDK.

---

## 6. **План на будущее**
- Если API часто меняется, рассмотреть использование схемы валидации (например, OpenAPI/Swagger) для автоматической генерации моделей и их обновления.

---

**Резюме:**  
- Документировать изменения и новые правила.
- Внедрить практику обязательных дефолтов для опциональных полей.
- Добавить тесты на отсутствие/избыток данных.
- Рассмотреть централизованный механизм обработки ошибок парсинга.
- Следить за обратной связью и поддерживать устойчивость SDK к изменениям API.

Если нужна помощь с каким-либо из этих шагов (например, с тестами или документацией) — дайте знать!

---

**User**

задокументируй данные изменения

---

**Cursor**

```markdown

## Безопасная обработка опциональных полей моделей

Начиная с версии [указать версию], все опциональные поля моделей (`attribute?`) в SDK имеют явное значение по умолчанию (`nil`). Это означает:

- Если в ответе API отсутствует опциональное поле, SDK не выбрасывает ошибку и не падает.
- Для всех новых опциональных полей обязательно указывать `.optional.default(nil)` или другое подходящее значение по умолчанию.
- Это повышает устойчивость SDK к эволюции и частичным сбоям API.

### Пример
```ruby
attribute? :foo, Types::String.optional.default(nil)
```

### Рекомендации для контрибьюторов
- При добавлении новых моделей или полей используйте `.optional.default(nil)` для всех опциональных полей.
- Не оставляйте опциональные поля без дефолта — это может привести к ошибкам при изменениях API.
- Добавляйте тесты на обработку отсутствующих данных в моделях.

```

Изменения задокументированы в README:

- Добавлен раздел о безопасной обработке опциональных полей моделей.
- Описано, что теперь все `attribute?` имеют дефолт `nil`, SDK не падает при отсутствии данных.
- Даны рекомендации для контрибьюторов: всегда указывать дефолт для новых опциональных полей и добавлять тесты на отсутствие данных.

Если нужно обновить версию или добавить дополнительную информацию — сообщите!

