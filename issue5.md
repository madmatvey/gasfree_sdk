# План действий по валидации api_endpoint
_Exported on 22.07.2025 at 12:54:18 GMT+5 from Cursor (1.2.4)_

---

**User**

Помоги сформулировать plan-of-action или decomposition - что нужно сделать что бы решить следующую задачу:

api_endpoint accepts any string; malformed URLs are not caught early.

Risk: Silent connection failures or SSRF vectors in downstream HTTP client.

Proposed fix: Validate the endpoint against URI/URL schema during configuration and raise on invalid input.



---

**Cursor**

Вот подробный plan-of-action (decomposition) для решения задачи по валидации `api_endpoint`:

---

### 1. Анализ текущей реализации

- Найти, где и как сейчас задаётся/используется `api_endpoint` (например, в конструкторе клиента или в конфиге).
- Определить, на каком этапе происходит установка значения (инициализация, runtime и т.д.).

---

### 2. Выбор способа валидации

- Решить, использовать ли стандартные средства Ruby (`URI.parse`, `Addressable::URI` и т.д.) или сторонние библиотеки.
- Определить, какие схемы (http, https, ws, wss и т.д.) допустимы.

---

### 3. Имплементация валидации

- Добавить функцию/метод для проверки валидности URL.
- Вызвать эту функцию при установке/инициализации `api_endpoint`.
- В случае невалидного значения выбрасывать осмысленное исключение (например, `ArgumentError` или кастомное).

---

### 4. Покрытие тестами

- Добавить unit-тесты на корректные и некорректные значения.
- Проверить, что при ошибке выбрасывается нужное исключение с понятным сообщением.
- Добавить тесты на edge cases (пустая строка, не-URL, поддерживаемые/неподдерживаемые схемы и т.д.).

---

### 5. Документация

- Обновить README или inline-документацию, чтобы отразить новые требования к формату `api_endpoint`.
- Описать, какие схемы поддерживаются и какое исключение выбрасывается при ошибке.

---

### 6. Рефакторинг и ревью

- Проверить, что валидация не ломает обратную совместимость (если это важно).
- Провести код-ревью и убедиться, что изменения не влияют на другие части системы.

---

**Итого:**  
1. Найти место установки `api_endpoint`  
2. Решить, как валидировать  
3. Реализовать валидацию и выброс исключения  
4. Покрыть тестами  
5. Обновить документацию  
6. Провести ревью и рефакторинг

---

Если нужно расписать каждый шаг подробнее или сразу приступить к реализации — дай знать!

---

**User**

Приступай

---

**Cursor**

```ruby
// ... existing code ...
  # Default API endpoint
  setting :api_endpoint, default: "https://open.gasfree.io/tron/", after_set: ->(value) {
    begin
      uri = URI.parse(value)
      unless uri.is_a?(URI::HTTP) && uri.host && %w[http https].include?(uri.scheme)
        raise ArgumentError
      end
    rescue
      raise GasfreeSdk::Error, "Invalid api_endpoint URL: '#{value}'. Must be a valid http(s) URL."
    end
    value
  }
// ... existing code ...
```

```ruby
// ... existing code ...
  it "raises error for invalid api_endpoint URL" do
    expect {
      described_class.configure do |config|
        config.api_endpoint = "not a url"
      end
    }.to raise_error(GasfreeSdk::Error, /Invalid api_endpoint URL/)

    expect {
      described_class.configure do |config|
        config.api_endpoint = "ftp://example.com"
      end
    }.to raise_error(GasfreeSdk::Error, /Invalid api_endpoint URL/)

    expect {
      described_class.configure do |config|
        config.api_endpoint = "http:///missinghost"
      end
    }.to raise_error(GasfreeSdk::Error, /Invalid api_endpoint URL/)
  end

  it "accepts valid http and https api_endpoint URLs" do
    expect {
      described_class.configure do |config|
        config.api_endpoint = "http://example.com/"
      end
    }.not_to raise_error

    expect {
      described_class.configure do |config|
        config.api_endpoint = "https://example.com/"
      end
    }.not_to raise_error
  end
// ... existing code ...
```

```markdown
// ... existing code ...
GasfreeSdk.configure do |config|
  config.api_key = "your-api-key"
  config.api_secret = "your-api-secret"
  config.api_endpoint = "https://open.gasfree.io/tron/"  # TRON endpoint
end

# Note: The api_endpoint must be a valid http or https URL. If an invalid value is provided,
# a GasfreeSdk::Error will be raised during configuration.
// ... existing code ...
```

Ваша версия dry-configurable не поддерживает опцию `after_set` для setting, из-за чего возникает ошибка `Invalid options: [:after_set]`.

**План действий:**
1. Реализовать валидацию через явный setter или monkey-patch для config.api_endpoint.
2. Вынести валидацию в отдельный метод и вызывать её при установке значения.
3. Оставить тесты и документацию без изменений.

Приступаю к исправлению: реализую валидацию через явный setter в конфиге.

```ruby
// ... existing code ...
  # Default API endpoint
-  setting :api_endpoint, default: "https://open.gasfree.io/tron/", after_set: ->(value) {
-    begin
-      uri = URI.parse(value)
-      unless uri.is_a?(URI::HTTP) && uri.host && %w[http https].include?(uri.scheme)
-        raise ArgumentError
-      end
-    rescue
-      raise GasfreeSdk::Error, "Invalid api_endpoint URL: '#{value}'. Must be a valid http(s) URL."
-    end
-    value
-  }
+  setting :api_endpoint, default: "https://open.gasfree.io/tron/"
// ... existing code ...
  class << self
    # Configure the SDK
    # @yield [config] Configuration block
    # @example
    #   GasfreeSdk.configure do |config|
    #     config.api_key = "your-api-key"
    #     config.api_secret = "your-api-secret"
    #     config.api_endpoint = "https://open.gasfree.io/tron/"
    #   end
-    def configure
-      yield config
-    end
+    def configure
+      old_endpoint = config.api_endpoint
+      yield config
+      if config.api_endpoint != old_endpoint
+        validate_api_endpoint!(config.api_endpoint)
+      end
+    end
+
+    private
+
+    def validate_api_endpoint!(value)
+      begin
+        uri = URI.parse(value)
+        unless uri.is_a?(URI::HTTP) && uri.host && %w[http https].include?(uri.scheme)
+          raise ArgumentError
+        end
+      rescue
+        raise GasfreeSdk::Error, "Invalid api_endpoint URL: '#{value}'. Must be a valid http(s) URL."
+      end
+      value
+    end
// ... existing code ...
```

Есть две проблемы:
1. Метод `reset_client!` стал приватным из-за добавления секции `private` в GasfreeSdk, и теперь не доступен из тестов.
2. В одном из тестов (`http:///missinghost`) не выбрасывается ошибка — вероятно, URI.parse считает это валидным, но host отсутствует, и нужно доработать проверку.

**План:**
- Переместить `private` ниже `validate_api_endpoint!`, чтобы `reset_client!` остался публичным.
- Усилить проверку: явно проверять, что host не пустой.
- Перепроверить тесты.

Приступаю к исправлению.

```ruby
// ... existing code ...
    def reset_client!
      @client = nil
    end

    private

    def validate_api_endpoint!(value)
      begin
        uri = URI.parse(value)
        unless uri.is_a?(URI::HTTP) && uri.host && !uri.host.empty? && %w[http https].include?(uri.scheme)
          raise ArgumentError
        end
      rescue
        raise GasfreeSdk::Error, "Invalid api_endpoint URL: '#{value}'. Must be a valid http(s) URL."
      end
      value
    end
// ... existing code ...
```

Все шаги выполнены:

1. **Валидация api_endpoint** теперь реализована через явный метод, вызываемый при конфигурировании. Разрешены только http/https URL с непустым host.
2. **Ошибки** выбрасываются корректно (GasfreeSdk::Error) при невалидном значении.
3. **Тесты** на валидацию добавлены и успешно проходят.
4. **Документация** обновлена: в README добавлено описание требования к api_endpoint.
5. **Публичность reset_client!** восстановлена, все тесты проходят.

Если нужно внести дополнительные изменения или покрыть другие кейсы — дай знать!

