module Todo

  module Asker
    def self.multi(fields)
      params = {}
      fields.each do |field|
        params.merge! single(field)
      end
      params
    end
    def self.single(field)
      {field => ask(field)}
    end
    def self.ask(field)
      print "#{field.to_s.capitalize.tr('_', ' ')}:_ "
      gets.strip
    end
  end

  module Menu
    def self.append_features(klass)
      def klass.menu
        @commands ||= constants.reject{ |command| command =~ /basic/i }.collect { |command| const_get(command).extend(MenuItem) }.sort { |a, b| a::KEY <=> b::KEY }
        print_menu
        process_user_input
      end
      def klass.print_menu
        puts
        @commands.each do |command|
          puts command.menu_item
        end
      end
      def klass.process_user_input
        print 'Command:_ '
        user_input = gets.strip.downcase
        puts
        command = @commands.detect { |command| command::KEY.eql? user_input }
        call_command(command) if command
      end
    end
  end

  module MenuItem
    def menu_item
      "#{self::KEY}\t#{self::DESCRIPTION}"
    end
  end

  module Commands

    module BasicList
      def print_list(items)
        items.each do |item|
          puts item
        end
      end
    end

    class GeneralCommands
      class BasicTaskList
        extend BasicList
        def self.task_list_body(tasks)
          unless tasks.empty?
            print_list tasks
          else
            puts 'There are no tasks'
          end
        end

        def self.execute(conditions)
          tasks = Task.with_all.filter(conditions)
          task_list_body(tasks)
          unless tasks.empty?
            task = Task.filter(conditions.merge(Asker.single(:id)))
            unless task.empty?
              BasicTaskManipulation.run(task)
            end
          end
        end
      end

      class ListDoneTasks < BasicTaskList
        KEY = 'd'
        DESCRIPTION = 'List done tasks'
        def self.execute
          puts 'Done tasks'
          task_list_body(Task.with_all.filter(:done => true))
        end
      end

      class ListUndoneTasks < BasicTaskList
        KEY = 'l'
        DESCRIPTION = 'List undone tasks'
        def self.execute
          puts 'Tasks to do'
          super(:done => false)
        end
      end

      class AddTask
        KEY = 'a'
        DESCRIPTION = 'Add new task'
        REQUIRED_ATTRIBUTES = [:description, :priority]
        SUCCESS_MESSAGE = 'Task created'
        FAIL_MESSAGE = 'Could not create task'

        def self.execute
          params = Asker.multi(REQUIRED_ATTRIBUTES)
          Task.association_reflections.each do |k, v|
            params.merge!(v[:key] => const_get(v[:class_name]).find_or_create(:name => Asker.ask(k)).id)
          end
          puts Task.insert(params).zero? ? FAIL_MESSAGE: SUCCESS_MESSAGE
        end
      end

      class Exit
        KEY = 'x'
        DESCRIPTION = 'Exit the program'
        def self.execute
          exit
        end
      end

      class ListContexts
        KEY = 'c'
        DESCRIPTION = 'List contexts'
        extend BasicList
        def self.execute
          puts 'List of contests'
          contexts = Context.active
          unless contexts.empty?
            print_list(contexts)
            conditions = { :done => false }.merge(Asker.single(:context_id))
            BasicTaskList.execute(conditions)
          else
            puts 'There are no contexts'
          end
        end
      end

      class ListProjects
        KEY = 'p'
        DESCRIPTION = 'List projects'
        extend BasicList
        def self.execute
          puts 'List of projects'
          projects = Project.active
          unless projects.empty?
            print_list(projects)
            conditions = { :done => false }.merge(Asker.single(:project_id))
            BasicTaskList.execute(conditions)
          else
            puts 'There are no projects'
          end
        end
      end

      include Menu

      def self.run
        loop { menu }
      end

      def self.call_command(command)
        command.execute
      end
    end

    class BasicTaskManipulation

      module BasicMessages
        FAIL_MESSAGE = 'Could not update task'
        SUCCESS_MESSAGE = 'Task successfuly updated'
      end
      class RemoveTask
        KEY = 'r'
        DESCRIPTION = 'Remove task'
        FAIL_MESSAGE = 'Could not remove task'
        SUCCESS_MESSAGE = 'Task successfuly removed'
        def self.execute(task)
          task.delete
        end
      end

      class MarkTaskDone
        KEY = 'd'
        DESCRIPTION = 'Mark task as done'
        include BasicMessages
        def self.execute(task)
          task.update(:done => true)
        end
      end

      class ChangeTaskPriority
        KEY = 'i'
        DESCRIPTION = 'Change priority of the task'
        include BasicMessages
        def self.execute(task)
          task.update(Asker.single(:priority))
        end
      end

      class ChangeTaskProject
        KEY = 'p'
        DESCRIPTION = 'Change project of the task'
        include BasicMessages
        def self.execute(task)
          project_id = Project.find_or_create(:name => Asker.ask(:project)).id
          task.update(:project_id => project_id)
        end
      end

      class ChangeTaskContext
        KEY = 'c'
        DESCRIPTION = 'Change context of the task'
        include BasicMessages
        def self.execute(task)
          context_id = Context.find_or_create(:name => Asker.ask(:context)).id
          task.update(:context_id => context_id)
        end
      end

      include Menu

      def self.run(task)
        @task = task
        menu
      end

      def self.call_command(command)
        puts command.execute(@task).to_i.zero? ? command::FAIL_MESSAGE : command::SUCCESS_MESSAGE
      end
    end
  end
end
