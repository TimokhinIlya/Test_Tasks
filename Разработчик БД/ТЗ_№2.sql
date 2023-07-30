/*
Для реализации древовидных данных без использования специфических типов можно воспользоваться структурой "Closure Table". 
    Closure Table (таблица связей)- это дополнительная таблица, которая хранит все пути в древовидной структуре между узлами. 
    Это позволяет выполнять запросы без рекурсии и эффективно извлекать дочерние элементы, подчиненные элементы и т.д. для произвольного узла.
*/

--Основная таблица "Nodes", которая будет хранить информацию о каждом узле дерева:
CREATE TABLE Nodes (
    NodeID INT IDENTITY(1,1) PRIMARY KEY,
    NodeName NVARCHAR(100) NOT NULL
);

--Таблица "Closure", которая будет содержать путь между каждой парой узлов в древовидной структуре:
CREATE TABLE Closure (
    AncestorID INT NOT NULL,
    DescendantID INT NOT NULL,
    Depth INT NOT NULL,
    PRIMARY KEY (AncestorID, DescendantID),
    FOREIGN KEY (AncestorID) REFERENCES Nodes(NodeID),
    FOREIGN KEY (DescendantID) REFERENCES Nodes(NodeID)
);

-- Вставка данных в таблицу Nodes для тестирования
INSERT INTO Nodes (NodeName)
VALUES
    ('A'),
    ('B'),
    ('C'),
    ('D'),
    ('E'),
    ('F'),
    ('G'),
    ('H');

-- Вставка данных в таблицу Closure для тестирования
INSERT INTO Closure (AncestorID, DescendantID, Depth)
VALUES
    (1, 1, 0),
    (1, 2, 0),
    (1, 3, 0),
    (1, 4, 0),
    (1, 5, 0),
    (1, 6, 0),
    (1, 7, 0),
    (1, 8, 0),
    (2, 2, 1),
    (2, 4, 1),
    (2, 5, 1),
    (3, 3, 1),
    (3, 6, 1),
    (3, 7, 1),
    (3, 8, 1),
    (4, 4, 2),
    (5, 5, 2),
    (6, 6, 2),
    (6, 8, 2),
    (7, 7, 2),
    (8, 8, 3);

--Хранимая процедура для выборки всех потомков определенного узла:
CREATE PROCEDURE Get_Child_Nodes
    @Parent_NodeID INT
AS
BEGIN
    SELECT NodeID, NodeName
    FROM Nodes AS N
    JOIN Closure AS L on N.NodeID = L.DescendantID
    WHERE AncestorID = @Parent_NodeID
END;

--Хранимая процедура для выборки всех родителей определенного узла:
CREATE PROCEDURE Get_Parent_Nodes
    @Child_NodeID INT
AS
BEGIN
    SELECT NodeID, NodeName
    FROM Nodes AS N
    JOIN Closure AS L on N.NodeID = L.AncestorID
    WHERE DescendantID = @Child_NodeID
END;

--Хранимая процедура для удаления определенного узла:
CREATE PROCEDURE Delete_Node
    @NodeID INT
AS
BEGIN
    -- Удаляем связи узла с его потомками из таблицы "Closure"
    DELETE FROM Closure
    WHERE AncestorId = @NodeID OR DescendantId = @NodeID;

    -- Удаляем узел из таблицы "Nodes"
    DELETE FROM Nodes
    WHERE NodeID = @NodeID;
END;

--Хранимая процедура для добавления нового узла:
CREATE PROCEDURE Add_New_Node
    @New_NodeName NVARCHAR(100),
    @Parent_NodeID INT
AS
BEGIN
    DECLARE @New_NodeID INT, @Current_Depth INT, @Current_Parent_NodeID INT;

    -- Получаем значение глубины уровня для нового узла
    SET @Current_Depth = (SELECT TOP 1 Depth + 1 FROM Closure WHERE AncestorID = @Parent_NodeID);

    -- Сохраняем в переменной значение родителя нового узла
    SET @Current_Parent_NodeID = @Parent_NodeID;

    -- Добавление нового узла в таблицу "Nodes"
    INSERT INTO Nodes (NodeName)
    VALUES (@New_NodeName);

    -- Получаем последнее значение уникального индетификатора из столбца NodeID
    SET @New_NodeID = SCOPE_IDENTITY();

    -- Добавление связи нового узла
    INSERT INTO Closure (AncestorId, DescendantId, Depth)
    VALUES (@New_NodeID, @New_NodeID, @Current_Depth );

    -- Получаем значение глубины для родителя нового узла
    SET @Current_Depth = @Current_Depth - 1;

    -- Добавление связей для родителей нового узла
    WHILE (@Current_Depth > 0)
    BEGIN
        INSERT INTO Closure (AncestorId, DescendantId, Depth)
        VALUES (@Current_Parent_NodeID, @New_NodeID, @Current_Depth);
        SET @Current_Depth = @Current_Depth - 1;
        SET @Current_Parent_NodeID = (SELECT TOP 1 AncestorID FROM Closure WHERE DescendantID = @Parent_NodeID and Depth = @Current_Depth)
    END;
END;

--Создаем индекс для внешнего ключа (Для первичных ключей индексы создадутся автоматически)
CREATE INDEX Closure_DescendantId
ON Closure (DescendantId);