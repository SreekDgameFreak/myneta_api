require 'sequel'
require 'pg'

Sequel.migration do
    up do
        create_table(:states) do
            primary_key :id
            String :state, :null => false
            String :name, :null => false
            String :constituency, :null => false
            String :party, :null => false
            Integer :criminal_cases, :null => false
            String :education, :null => false
            BigDecimal :assets, :size=>[12, 2]
        end
    end

    down do
        drop_table(:states)
    end
end
