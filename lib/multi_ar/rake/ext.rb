
require "rake"

# @api private
# Extension to Rake to provide rename task.
module Rake
  # Extension to Rake to provide rename task.
  class Application
    # A Rake task to rename another Rake task.
    def rename_task(task, oldname, newname)
        if @tasks.nil?
          @tasks = {}
        end

        @tasks[newname.to_s] = task

        if @tasks.has_key? oldname
          @tasks.delete oldname
        end
    end
  end
end

# add new rename method to Rake::Task class
# to rename a task
class Rake::Task
  # Renames current Rake task.
  def rename(new_name)
    if !new_name.nil?
        old_name = @name

        if old_name == new_name
          return
        end

        @name = new_name.to_s
        application.rename_task(self, old_name, new_name)
    end
  end
end

