defmodule KeyValue.Router do
  @moduledoc """

  Основной модуль приложения
  Отвечает за роутинг
  Принимает запрос к стартовой странице, в противном случае возврачает 404 ошибку

  Доступные методы:

     # Получить список всех записей - метод: GET, параметры: %{} -> Возвращает код 200 со списком записей в формате JSON | 404
     # Получить - метод: GET, параметры: %{"key" => key} -> Возвращает код 200 с ключом и значением в формате JSON | 404
     # Создать - метод: POST, параметры: %{"key" => key, "value" => value, "ttl" => ttl} -> Возвращает код 201 | 409 если ключ уже создан
     # Обновить - метод: PUT, параметры: %{"key" => key, "value" => value, "ttl" => ttl} -> Возвращает код 204 | 404
     # Удалить - метод: DELETE, параметры: %{"key" => key} -> Возвращает код 200 | 404

  """

  use Plug.Router
  alias KeyValue.Distributor


  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug :match
  plug :dispatch

  # Главная страница, которая обрабатывает метод и значения
  # Возвращает код ответа и сообщения
  # И запускает шкедулер автоудаления
  match "/" do
    children = [
      KeyValue # Запуск шкедулера для авто очистки записей из хранилища
    ]
    opts = [strategy: :one_for_one, name: KeyValue.Supervisor]
    Supervisor.start_link(children, opts)

    # Вызываем метод обработки запросов в зависимости от метода и параметров переданных в запросе
    {status, result} = case Distributor.to_storage(conn.method, conn.params) do
      {status} -> {status, ''}
      {status, answer} -> {status, get_json_result(answer)}  # Кодируем ответ функции в JSON для ответа
    end

    # Отправляем ответ
    send_resp(conn, status, result)
  end

  # Кодируем в json и возвращаем ответ
  defp get_json_result(item) do
    {:ok, result} = JSON.encode(item)
    result
  end

  # В случае обращения к другому пути - ошибка
  match _ do
    send_resp(conn, 404, "")
  end

end
