class Dog 
attr_accessor :name, :breed, :id

    def initialize(name:, breed:, id: nil)
        @name = name
        @breed = breed
        @id = id
    end

    def self.drop_table
       DB[:conn].execute("DROP TABLE IF EXISTS dogs")
    end

    def self.create_table 
        sql = <<-SQL 
        CREATE TABLE IF NOT EXISTS dogs (
            id INTEGER PRIMARY KEY,
            name TEXT,
            breed TEXT
        )
        SQL
        DB[:conn].execute(sql)
    end
    
    def save
        if self.id 
            self.update
        else 
            sql = <<-SQL
            INSERT INTO dogs (name, breed)
            VALUES (?, ?)
            SQL
            DB[:conn].execute(sql, self.name, self.breed)
            @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
        end
        self
    end

    def update
        sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?"
        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end

    def self.create(name:, breed:)
        dog = Dog.new(name: name, breed: breed)
        dog.save
        dog 
    end

    def self.new_from_db(row)
        id = row[0]
        name = row[1]
        breed = row[2]
        self.new(name: name, breed: breed, id: id)
    end

    def self.find_by_id(id)
        dog = DB[:conn].execute("SELECT * FROM dogs WHERE id = ?", id).flatten
        Dog.new(name: dog[1], breed: dog[2], id: dog[0])
    end

    def self.find_or_create_by(name:, breed:)
        sql = <<-SQL
        SELECT * FROM dogs
        WHERE name = ? AND 
        breed = ?
        LIMIT 1
        SQL

        dog = DB[:conn].execute(sql, name, breed)

        if dog.empty? 
            dog = self.create(name: name, breed: breed)
        else
            dog_info = dog.first
            dog = Dog.new(id: dog_info[0], name: dog_info[1], breed: dog_info[2])
        end
        dog 
    end

    def self.find_by_name(name)
        sql = <<-SQL
        SELECT * FROM dogs
        where name = ?
        LIMIT 1
        SQL
        DB[:conn].execute(sql, name).map do |row|
            self.new_from_db(row)
        end.first
    end
end