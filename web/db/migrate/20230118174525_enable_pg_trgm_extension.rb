# frozen_string_literal: true

class EnablePgTrgmExtension < ActiveRecord::Migration[7.0]
  def up
    enable_extension("pg_trgm") unless extensions.include?("pg_trgm")
  end

  def down
    disable_extension("pg_trgm") if extensions.include?("pg_trgm")
  end
end
