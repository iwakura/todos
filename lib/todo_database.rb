unless DB.table_exists? :tasks
  DB.create_table :tasks do
    primary_key :id
    TrueClass   :done,        :default => false
    Integer     :project_id,  :default => 0,  :null => false
    Integer     :context_id,  :default => 0,  :null => false
    String      :description, :default => '', :null => false, :size => 200
    String      :priority,    :default => '', :null => false, :size => 1
  end
  DB.create_table :projects do
    primary_key :id
    String      :name, :default => '', :null => false, :size => 50
  end
  DB.create_table :contexts do
    primary_key :id
    String      :name, :default => '', :null => false, :size => 50
  end
end

class Project < Sequel::Model
  one_to_many :tasks
  def to_s
    "#{id}\t#{name.empty? ? 'n/a' : name}"
  end
  def self.active
    select('projects.*'.lit).join(:tasks, :project_id => :id).group(:project_id).order('lower(name)'.lit).filter(:tasks__done => false)
  end
end

class Context < Sequel::Model
  one_to_many :tasks
  def to_s
    "#{id}\t#{name.empty? ? 'n/a' : name}"
  end
  def self.active
    select('contexts.*'.lit).join(:tasks, :context_id => :id).group(:context_id).order('lower(name)'.lit).filter(:tasks__done => false)
  end
end

class Task < Sequel::Model
  many_to_one :project
  many_to_one :context
  def to_s
    "#{pk}\t#{description}\t" +
    "#{' Project: ' + project.name unless project.name.empty?}" +
    "#{' Context: ' + context.name unless context.name.empty?}" +
    "#{' Priority: ' + priority unless priority.empty?}"
  end
  def self.with_all
    select('tasks.*, projects.name, contexts.name'.lit).join(:projects, :id => :project_id).join(:contexts, :id => :tasks__context_id).order('done, length(priority) desc, lower(priority)'.lit)
  end
end
