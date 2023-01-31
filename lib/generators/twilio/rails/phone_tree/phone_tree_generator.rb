class Twilio::Rails::PhoneTreeGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def copy_template_tree
    template "tree.rb.erb", "app/phone_trees/#{file_name}_tree.rb"
  end

  def register_tree
    insert_into_file "config/initializers/twilio_rails.rb", "\n  config.phone_trees.register { #{class_name}Tree }", before: "\nend\n"
  end
end
