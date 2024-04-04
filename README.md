# Веб сервер хранилища Ключ-значения

## Установка

```shell
git clone https://github.com/kusma007/elixir_key_value.git
cd elixir_key_value
```

```elixir
mix deps.get
```

## Запуск тестов
```
mix test
```

## Запуск сервера
```
mix run --no-halt
```

По умолчанию доступен по адресу http://127.0.0.1:8080

Порт для запуска указывается через переменную cowboy_port в файле config/config.exs

## Запуск сборщика документации
```
mix docs
```



