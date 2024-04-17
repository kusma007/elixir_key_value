defmodule KeyValue.Storage do
  @moduledoc """

  Модуль хранилища
  Создает хранилище с параметром :table_name установленным в config/config.exs
  Содержит методы получения, сохранения, обновления и удаления записей

  """

  import Ex2ms

  @spec get_table_name() :: any()
  def get_table_name() do
    Application.get_env(:key_value, :table_name, :storage)
  end

  def open_close(func) do
    storage = :dets.open_file(get_table_name(), [type: :set])
    |> case do
      {:ok, storage} -> storage
      other -> throw other
    end

    {:ok, func.(storage)}

  catch e, err_v ->
    {e,err_v}
  after
    :dets.close(get_table_name())
  end

  @doc """
    Сохраняет запись в хранилище, если такой ключ ещё не создан
  """
  @spec insert(any(), any(), number()) :: boolean() | {:error, any()}
  def insert(key, value, ttl) do
    {:ok, result} = open_close fn table_name ->
      :dets.insert_new(table_name, {key, value, get_time() + ttl})
    end
    result
  end

  @doc """
    Получает текущую метку времени в timestamp
  """
  @spec get_time() :: integer()
  def get_time(), do: :os.system_time(:seconds)

  @doc """
    Проверяет и возвращает запись открывая и закрывая хранилище
  """
  @spec get(any()) :: :error | map()
  def get(key) do
    {:ok, result} = open_close fn table_name ->
      get(table_name, key)
    end
    result
  end

  @doc """
    Проверяет и возвращает запись или nil
  """
  @spec get(any(), any()) :: :error | map()
  def get(table, key) do
    case one(table, key) do
      [result] -> check(table, result)
      [] -> :error
    end
  end

  @doc """
    Получает запись из БД по ключу
  """
  @spec one(any(), any()) :: [tuple()] | {:error, any()}
  def one(table, key), do: :dets.lookup(table, key)

  @doc """
    Проверяет запись, не просроченна ли она,
    если просрочена, то удаляет
    если нет, то возвращает Map строки, где ключ - key, и значение - value,
    которые установили при создании
  """
  @spec check(any(), {any(), any(), any()}) :: :error | map()
  def check(table, {key, value, time}) do
    cond do
      time > get_time() ->
        %{ key => value } # Возвращает Map ключ-значение
        # [key, value, time] # Возвращает List со всеми параметрами записи
        # [key: key, value: value, time: time] # Возвращает Keyword list всех параметров записи
      :else ->
        delete(table, key) # Если время истекло, то удаляем запись
        :error
    end
  end

  @doc """
    Обновляет запись, если она не просрочена, в противном случае возвращает nil
  """
  @spec update(any(), any(), any()) :: :error | :ok
  def update(key, value, ttl) do
    {:ok, result} = open_close fn table_name ->
      case get(table_name, key) do
        :error -> :error
        _ -> only_insert({key, value, get_time() + ttl})
      end
    end
    result
  end

  @doc """
    Записывает запись в хранилище
  """
  @spec only_insert([tuple()] | tuple()) :: :error | :ok
  def only_insert(map) do
    case :dets.insert(get_table_name(), map) do
      :ok -> :ok
      _ -> :error
    end
  end

  @doc """
    Проверяем запись и удаляем, если она присутствует
  """
  @spec check_and_delete(any()) :: :error | :ok
  def check_and_delete(key) do
    {:ok, result} = open_close fn table_name ->
      case get(table_name, key) do
        :error -> :error
        _ -> delete(table_name, key)
      end
    end
    result
  end

  @doc """
    Удаление записи по ключу, открывая и закрывая файл хранилища
  """
  @spec delete(any()) :: :error | :ok
  def delete(key) do
    {:ok, result} = open_close fn table_name ->
      delete(table_name, key)
    end
    result
  end

  @doc """
    Удаление записи по ключу и названию хранилища
  """
  @spec delete(any(), any()) :: :error | :ok
  def delete(table, key) do
    case :dets.delete(table, key) do
      :ok -> :ok
      _ -> :error
    end
  end

  @doc """
    Очистка БД от просроченных записей
  """
  @spec clear_ttl() :: non_neg_integer() | {:error, any()}
  def clear_ttl() do
    {:ok, result} = open_close fn table_name ->
      time = get_time()
      :dets.select_delete(table_name, fun do {_, _, ttl} when ttl < ^time -> true end)
    end
    result
  end

  @doc """
    Возвращает список всех просроченных записей
  """
  @spec get_ttl_expire() :: list() | {:error, any()}
  def get_ttl_expire() do
    {:ok, result} = open_close fn table_name ->
      time = get_time()
      :dets.select(table_name, fun do {key, _, ttl} when ttl < ^time -> key end)
    end
    result
  end

  @doc """
    Возвращает список всех записей
  """
  @spec get_all() :: [list()] | {:error, any()}
  def get_all() do
    {:ok, result} = open_close fn table_name ->
      :dets.match(table_name, {:"$1", :"$2", :"$3"})
    end
    result
  end

  def delete_all() do
    :dets.delete_all_objects(get_table_name())
  end


end
