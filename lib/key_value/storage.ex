# R: Тут в целом норм, но видно подход из императивных ЯПов, со временем это пройдет =)
#
#    В императивных ЯПах зачастую существуют функции/методы, которые вызывают ради получения
#    side-effect-а, у тебя в коде ярким представителем таких функций являются open/close.
#    На прямую их результат не используется, они раскиданы всюду, их нужно не забыть вызывать
#    и прочие прелести side-effect-ых штук из императивщины.
#
#    По хорошему, в Elixir/Erlang и прочих ФП ЯПах, очень редко (читай никогда) функции не
#    вызываются для получения побочных эффектов, всегда их значение используется ниже по коду
#    или возвращается из функции. За исключением функций, которые явно намекают на это.
#    Например File.touch!(file_name), это функция создает файл и возвращает :ok, либо падает c
#    ошибкой. Но у таких функций всегда есть аналог в виде безопасных, File.touch(file_name),
#    который возвращает :ok | {:error, posix()}.
#
#    Общее правило такое, если ты знаешь, как обработать ошибку и она тебя полезна, тогда лучше
#    использовать безопасные аналоги и либо прокидывать ее выше, либо обрабатывать на месте.
#    Если ошибка для тебя критична, и дальше ты хз что с ней делать, можно просто ее поматчить
#    на месте и свалитсья с bad_match, либо вызывать аналог с ! знаком, который поматчит за тебя.
#    Но использовать это нужно в случае, когда в нормальном режиме, ничего сломаться не может или
#    продолженние бессмысленно.
#
#    Например мы пишем утилиту, которые по переданному ей url скачивает контент, в таком случае
#    мы можем написать что то вида, так как все что мы делаем, только скачиваем контент:
#      def get!(url) do
#        HttpClient.get!(url)
#      end
#    Обратная сторона этого, когда мы пишем утилиту, которая берет на вход файл, забирает от туда
#    множество url-ов и скачивает их все, в таком случае проблема с 1 url для нас не критична.
#    И можно было бы написать что то типа:
#      def get(file_path) do
#        file_path
#        #           | тут !, потому что проблемы с файлом для нас конец всего и без файла делать
#        #           v нам нечего
#        |> File.read!
#        |> String.split
#        |> Enum.map(fn url ->
#          url
#          |> HttpClient.get
#          |> case do
#            {:ok, content} -> {url, {:ok, content}}
#            {:error, error} -> {url, {:error, error}}
#          end
#        end)
#      end
#    Можно по другому записать, но я выше написал вербозно, что бы лучше понять.
#    В реальности я бы написал вот так:
#      def get(file_path) do
#        file_path
#        |> File.read!
#        |> String.split
#        |> Enum.map(&{&1, HttpClient.get(&1)})
#      end

defmodule KeyValue.Storage do
  @moduledoc """

  Модуль хранилища
  Создает хранилище с параметром :table_name установленным в config/config.exs
  Содержит методы получения, сохранения, обновления и удаления записей

  """

  import Ex2ms

  def get_table_name() do
    Application.get_env(:key_value, :table_name, :storage)
  end

  @doc """
    Открывает хранилище
  """
  @spec open() :: any()
  def open() do
    # R: А если не {:ok, table}? По хорошему нужно обрабатывать прочие случаи и стараться
    #    прокидывать ошибку как можно выше, если намерений прокидывать ее нет, лучше это явно
    #    указать с помощью простого матчинга:
    #      {:ok, table} = :dets.open_file(get_table_name(), [type: :set])
    #
    #    А если у нас просто матчинг, то и в функции open нет какого то смысла, разматчить можно
    #    сразу по месту
    case :dets.open_file(get_table_name(), [type: :set]) do
      {:ok, table} ->
        table
    end
  end

  @doc """
    Закрывает хранилище
  """
  @spec close() :: :ok | {:error, any()}
  # R: Так же функция сомнительной необходимости, она делает только то, что вызывает другую
  #    почему бы сразу не вызывать :dets.close(get_table_name()) прям по месту?
  #
  #    Далее она часто используется в кейсе, когда в начале что то открыли, потом закрыли
  #    везде в таких местах лучше закрывать в блоке after, что бы точно понимать, что коннект
  #    будет закрыт в любом случае.
  #
  #    А лучше вообще использовать паттерн ресурса, ниже в функции insert описал пример.
  def close(), do: :dets.close(get_table_name())

  @doc """
    Сохраняет запись в хранилище, если такой ключ ещё не создан
  """
  @spec insert(any(), any(), number()) :: boolean() | {:error, any()}
  # R: Тут нет проверки на то, что у нас успешно произошло открытие, оно конечно само собой получиться
  #    так как в open нет матчинга на неуспешность, но обычно в Elixir, функции которые могут упасть
  #    помечают восклицательным значком, например open!(...) или insert!(...).
  #
  #    Плюс игнорируется возвращаемый аргумент функции open, тогда какой в нем смысл?
  #    В целом, если open у нас что то с семантикой ресурса, тут я имею в виду что это какой то
  #    временный обьект, который открывается, выполняет что то и потом закрывается, его можно
  #    было бы написать чуть красивее, например вот так:
  #      def with_db!(f) do
  #        {:ok, db} = :dets.open_file(get_table_name(), [type: :set])
  #        f.(db)
  #      after ->
  #        :dets.close(get_table_name())
  #      end
  #
  #    Или безопасный аналог:
  #      def with_db(f) do
  #        db = :dets.open_file(get_table_name(), [type: :set])
  #        |> case do
  #          {:ok, db} -> db
  #          other -> throw other
  #        end
  #
  #        {:ok, f.(db)}
  #      catch e, err_v ->
  #        {e, err_v}
  #      after ->
  #        :dets.close(get_table_name())
  #      end
  #
  #    Пример использования:
  #      ...
  #      with_db fn db ->
  #        :dets.insert_new(db, {key, value, get_time() + ttl})
  #      end
  #      ...
  #
  #    Безопасный инвариант всегда можно выразить через небезопасный + форма try или ее аналог.
  def insert(key, value, ttl) do
    open()
    result = :dets.insert_new(get_table_name(), {key, value, get_time() + ttl})
    close()
    result
  end

  @doc """
    Получает текущую метку времени в timestamp
  """
  @spec get_time() :: integer()
  # R: Тут то же самое, функция ради функции, почему не сразу :os.system_time(:seconds)
  def get_time(), do: :os.system_time(:seconds)

  @doc """
    Проверяет и возвращает запись открывая и закрывая хранилище
  """
  @spec get(any()) :: :error | map()
  def get(key) do
    result = get(open(), key)
    close()
    result
  end

  @doc """
    Проверяет и возвращает запись или nil
  """
  @spec get(any(), any()) :: :error | map()
  # R: Ошибку лучше всего делать макисмально специфичную, что бы вызывающий стороне было
  #    понятно в чем дело, :error слишком общее название, хорош было бы если ошибка была бы:
  #    {:error, :empty_result} или типа того, а в целом, есть ли проблема в том, что по ключу
  #    не вернулась запись? Может быть оставить просто nil? А уже на стороне вызывающего кода
  #    разобраться с результатом, например:
  #      ...
  #      get(get_table_name(), "not_exist_key") || raise "Запрощенный ключ не найден"
  #      ...
  #    Или подставление дефолта:
  #      ...
  #      get(get_table_name(), "not_exist_key") || "<empty>"
  #      ...
  #
  #
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
    # R: cond...do классно заходит когда надо проверять много условий, а тут всего два,
    #    лучше будет воспользоваться if/unless или вообще вот так:
    #      time > get_time() && %{ key => value } || (
    #        delete(table, key)
    #        :error
    #      )
    cond do
      time > get_time() ->
        %{ key => value } # Возвращает Map ключ-значение
        # [key, value, time] # Возвращает List со всеми параметрами записи
        # [key: key, value: value, time: time] # Возвращает Keyword list всех параметров записи
      :else ->
        delete(table, key) # Если время истекло, то удаляем запись
        :error # R: Очень общее описание ошибки, лучше уточнять
    end
  end

  @doc """
    Обновляет запись, если она не просрочена, в противном случае возвращает nil
  """
  @spec update(any(), any(), any()) :: :error | :ok
  def update(key, value, ttl) do
    result = case get(open(), key) do
      :error -> :error
      _ -> only_insert({key, value, get_time() + ttl})
    end
    close()
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
    table = open()
    result = case get(table, key) do
      :error -> :error
      _ -> delete(table, key)
    end
    close()
    result
  end

  @doc """
    Удаление записи по ключу, открывая и закрывая файл хранилища
  """
  @spec delete(any()) :: :error | :ok
  def delete(key) do
    result = delete(open(), key)
    close()
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
    time = get_time()
    # R: Частая проблема тех, кто начинает работать с ets/dets, это использования Ex2ms
    #    match_spec, это неотьемлемая часть erlang, небольшой язык для описания запросов
    #    он достаточно простой, с ним можно разобраться и писать сразу match_spec без
    #    доп нагрузки в виде преобразования из elixir в match_spec.
    #    В будущем будет проще отлаживать запросы, обычно их пишут без использования Ex2ms.
    #    Но в целом не особо проблема.
    count = :dets.select_delete(open(), fun do {_, _, ttl} when ttl < ^time -> true end)
    close()
    count
  end

  @doc """
    Возвращает список всех просроченных записей
  """
  @spec get_ttl_expire() :: list() | {:error, any()}
  def get_ttl_expire() do
    time = get_time()
    result = :dets.select(open(), fun do {key, _, ttl} when ttl < ^time -> key end)
    close()
    result
  end

  @doc """
    Возвращает список всех записей
  """
  @spec get_all() :: [list()] | {:error, any()}
  def get_all() do
    :dets.match(open(), {:"$1", :"$2", :"$3"})
  end

  def delete_all() do
    :dets.delete_all_objects(get_table_name())
  end


end
