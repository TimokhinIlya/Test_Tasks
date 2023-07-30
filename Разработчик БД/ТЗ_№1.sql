DECLARE @p1 NVARCHAR(4000) = N'ф%', @p2 NVARCHAR(4000) = N'к%', @p3 NVARCHAR(4000) = N'423'
SELECT PersonSurName_SurName, PersonFirName_FirName, PersonSecName_SecName, PersonBirthDay_BirthDay, work.Org_Nick, PersonCard_Code
FROM tmp.person (NOLOCK) p 
left JOIN tmp.personstate (nolock) ps ON p.person_id = ps.person_id 
    OUTER APPLY 
    (SELECT TOP 1 o.Org_Nick 
    FROM dbo.org (NOLOCK) o 
    INNER JOIN dbo.job (nolock) j ON j.org_id = o.org_id  
    WHERE ISNULL(o.Region_id, dbo.GetRegion()) = dbo.GetRegion() AND j.job_id = ps.job_id 
    ORDER BY o.Org_endDate DESC) work 
    OUTER APPLY 
    (SELECT TOP 1 PersonCard_id, PersonCard_Code, PersonCard_begDate, PersonCard_endDate, LpuAttachType_Name, LpuRegionType_Name, PersonCard_IsAttachCondit, PersonCardAttach_id, LpuRegion_id, Lpu_id, LpuRegion_fapid 
    FROM v_PersonCard PC with (nolock) 
    WHERE PC.Person_id = PS.Person_id AND PC.Lpu_id = @P3 
    ORDER BY LpuAttachType_id) PersonCard
WHERE ISNULL(p.person_deleted,1) = 1 AND ps.sex_id = 2 AND (ps.PersonSurName_SurName LIKE @p1 OR ps.PersonSurName_SurName LIKE @p2) AND p.Person_updDT <= dbo.tzGetDate() 
ORDER BY PersonSurName_SurName, PersonFirName_FirName, PersonSecName_SecName


-- Исправленная версия
DECLARE @p1 NVARCHAR(2) = N'ф%', @p2 NVARCHAR(2) = N'к%', @p3 VARCHAR(3) = '423', @RegionID INT = dbo.GetRegion()
SELECT PersonSurName_SurName, PersonFirName_FirName, PersonSecName_SecName, PersonBirthDay_BirthDay, Work.Org_Nick, PersonCard.PersonCard_Code
FROM tmp.person (NOLOCK) p 
LEFT JOIN tmp.personstate (NOLOCK) ps ON p.person_id = ps.person_id 
    CROSS APPLY 
    (SELECT TOP 1 o.Org_Nick 
    FROM dbo.org (NOLOCK) o 
    INNER JOIN dbo.job (NOLOCK) j ON j.org_id = o.org_id  
    WHERE ISNULL(o.Region_id, @RegionID) = @RegionID AND j.job_id = ps.job_id 
    ORDER BY o.Org_endDate DESC) Work 
    CROSS APPLY 
    (SELECT TOP 1 PersonCard_Code
    FROM v_PersonCard PC with (NOLOCK) 
    WHERE PC.Person_id = PS.Person_id AND PC.Lpu_id = @p3 
    ORDER BY LpuAttachType_id) PersonCard
WHERE ISNULL(p.person_deleted, 1) = 1 AND ps.sex_id = 2  AND p.Person_updDT <= dbo.tzGetDate() AND (ps.PersonSurName_SurName LIKE @p1 OR ps.PersonSurName_SurName LIKE @p2)
ORDER BY PersonSurName_SurName, PersonFirName_FirName, PersonSecName_SecName;


/* 

Ниже представлены варианты оптимизации данного запроса с учетом различных допущений:

1. Следует уменьшить максимальное количество возможных символов для локальных переменных @p1...@p3.
    В данном случае предполагается использовать переменные для нахождения конкретных фамилий по совпадению первых букв с помощью оператора LIKE (допускаю что фамилии хранятся в нижнем регистре). 
    Тогда хранение переменных в NVARCHAR(4000) является избыточным.
    Также если мы уверены, что нам не понадобится хранить символы Юникода, VARCHAR может быть более эффективным с точки зрения использования памяти и производительности (1 байт на символ вместо 2).
    Локальная переменная @p3 необходима для проверки уникального идентификатора, для определения которого обычно используют латинские цифры (которые есть в ASCII). 
    Тогда нет особого смысла хранить его в NVARCHAR (Если в столбце Lpu_id хранятся данные с числовым типом, тогда для @p3 необходимо изменить VARCHAR на INT).

2. Следует поменять OUTER APPLY на CROSS APPLY.
    Если нам нужны только строки для которых выполняются все условия, то следует воспользоваться CROSS APPLY, чтобы исключить из результирующего запроса строки с пустыми значениями. 
    Тогда CROSS APPLY может быть более эффективным решением с точки зрения производительности.

3. Вместо множественных вызовов функции "dbo.GetRegion()", можно предварительно вычислить значение и сохранить его в локальной переменной.

4. Для второго по счету OUTER APPLY следует выбрать только столбец PersonCard_Code, а все остальные исключить из подзапроса. 
    В итоговом результирующем наборе нам не нужно отображать остальные столбцы из таблицы v_PersonCard.

5. Необходимо измененить очередность проверки условий для последнего WHERE.
    Данная операция - "ps.PersonSurName_SurName LIKE @p1 OR ps.PersonSurName_SurName LIKE @p2" может быть довольно трудоемкой, ее следует выполнять, только если выполняются все остальные условия.


Замечания к коду:

1. Названия операций, идентификаторов написаны в разном регистре, например: left JOIN, nolock, @P3. 
    Такой код является корректным и не вызовет синтаксической ошибки, но все же рекомедуется придерживаться единого стиля.

2. В строке кода "SELECT PersonSurName_SurName, PersonFirName_FirName, PersonSecName_SecName, PersonBirthDay_BirthDay, work.Org_Nick, PersonCard_Code" допущена синтаксическая ошибка.
    Название столбца "PersonCard_Code" необходимо изменить на "PersonCard.PersonCard_Code".

3. Предполагаю, что в данном случае хинт NOLOCK используется для оптимизации производительности запроса при параллельных транзакциях. 
    Конечно, я не знаю всех нюансов, но все же следует аккуратно использовать подобные инструменты. 
    В данном случае при использовании NOLOCK мы избегаем блокировки и обходим стандартный уровень изоляции ReadCommited, что, в худшем случае, может привести к "грязному чтению".


Общие сведения по оптимизации:

1. Необходимо убедиться что индексы построены для всех первичных и внешних ключей, а также для соответствующих атрибутов используемых в условиях присоединения (JOIN) и фильтрации (WHERE). 
    Например: person_id, org_id, job_id, Person_id, Lpu_id.

2. Создать материализованные представления для хранения подзапросов (если предполагается их частое использование).

3. Необходимо убедиться в актуальности статистики для таблиц и индексов в базе данных.
    Обновление статистики поможет планировщику принимать более обоснованные решения о плане выполнения запросов.

4. Для конкретных рекомендация по оптимизации данного запроса не обойтись без анализа плана выполнения запросов.
    Он необходим для понимания:
    - Метода доступа к данным (index scan, index only scan и т. п.). Проверки правильности работы индексов и их оптимизации.
    - Метода соединения (nested loop join, hash join, merge join)
    - Особенности запросов, то есть как сервер обрабатывает условия, группировку, сортировку и агрегатные функции и т. п. в запросе.
    Все выше перечисленное помогает идентифицировать узкие места и возможные проблемы производительности, 
    что позволяет предпринять действия по оптимизации запроса путем редактирования кода или же изменения структурных особенностей базы данных.

*/

