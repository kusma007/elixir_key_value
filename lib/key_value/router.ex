defmodule KeyValue.Router do
  @moduledoc """

  Модуль роутинга приложения
  """

  use Plug.Router
  alias KeyValue.Distributor


  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug :match
  plug :dispatch

  # Главная страница, которая обрабатывает метод и значения
  # Возвращает код ответа и сообщения
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
