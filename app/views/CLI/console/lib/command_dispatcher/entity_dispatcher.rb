###
#
# Dispatcher for "entity" commands
#
###


module Poortego
module Console
module CommandDispatcher

###
#
# Entity Dispatcher Class
#
### 
class EntityDispatcher
  
  # Inherit from CommandDispatcher
  include Poortego::Console::CommandDispatcher

  #
  # Constructor
  #
  def initialize(driver)
    super
  end
  
  #
  # Support these commands
  #
  def commands
    {
      ## TODO: these will likely change?  For example, be included in the Home set command?
      "entitytype" => "Set entity type",
      "field"      => "Manipulate Entity Field",
      # This one is probably good:
      "linkto"     => "Link entity to another", 
    }
  end
  
  #
  # Dispatcher Name
  #
  def name
    "Entity"
  end
  
  #
  # Link current entity to another
  #
  def cmd_linkto(*args)
    project_id = driver.interface.working_values["Current Project"].id
    section_id = driver.interface.working_values["Current Section"].id
    entity_id  = driver.interface.working_values["Current Entity"].id
    entity_obj = Entity.find(entity_id)
    
    linkto_entity_name = args[0]
    if ((linkto_entity_name == '-h') || (linkto_entity_name == '-?'))
      cmd_linkto_help
      return
    end
    
    link_name = driver.interface.working_values["Current Entity"].title + " --> " + linkto_entity_name
    
    link_id = Link.select_or_insert(project_id, section_id, entity_obj.title, linkto_entity_name, link_name)
    driver.interface.working_values["Current Link"] = Link.find(link_id)
    driver.interface.working_values["Current Object"] = driver.interface.working_values["Current Link"]
    driver.interface.working_values["Current Selection Type"] = 'link'
    driver.enstack_dispatcher(LinkDispatcher)
    set_prompt()
  end
  
  #
  # "linkto" command help
  #
  def cmd_linkto_help
    print_status("Command    : linkto")
    print_status("Description: link the current entity to another.")
    print_status("Usage      : 'linkto <entity>'")
  end
  
  #
  # "field" command logic
  #
  def cmd_field(*args)
    
    entity_id    = driver.interface.working_values["Current Entity"].id
    field_action = nil
    field_name   = nil
    
    if (args.length < 1)
      field_action = list
    else 
      field_action = args[0] # list, set, add, remove
      if (args.length >= 2)
        field_name   = args[1]
      end
    end
    
    case field_action
    when '-h', '?'
      cmd_field_help
      return
    when 'list'  
      field_value = EntityField.list_with_values(entity_id)
      field_value.each {|key,value|
       puts "#{key}  |  #{value}"  
      }
    when 'set'
      field_value = args[2]
      
      field_id   = EntityField.select_or_insert(entity_id, field_name)
      puts "[DEBUG] EntityField Id: #{field_id}"
      field_obj  = EntityField.find(field_id)
      field_obj.update_attributes(:value => field_value)
      field_obj.save    
    when 'add'
      EntityField.select_or_insert(entity_id, field_name)
    when 'remove'
      EntityField.delete_from_name(entity_id, field_name)      
    end  
    
  end
  
  #
  # "Field" command help
  #
  def cmd_field_help
    print_status("Command    : field")
    print_status("Description: manipulate fields for current entity.")
    print_status("Usage      : 'field <action> <field_name> [field_value]'")
    print_status("Details    :")
    print_status("Where action is: list, set, add, remove.") 
    print_status("The field_value parameter is only used for set.")    
  end
  
  #
  # "entitytype" command logic
  #
  def cmd_entitytype(*args)
    
    if (args.length < 1)
      cmd_entitytype_help
      return
    end
    
    type_name = args[0]
    if ((type_name == '-h') || (type_name == '-?'))
      cmd_entitytype_help
      return
    end
    
    type_id = EntityType.select(type_name)
    if (type_id < 1)
      print_error("Invalid entitytype name.")
      return
    end
    
    entity_id = driver.interface.working_values["Current Entity"].id
    
    # Get the fields tied to the type
    field_rows = EntityTypeField.find(:all, :conditions => "entity_type_id=#{type_id}", :order => "field_name ASC")
    field_rows.each do |field_row|
          # Add field_row['field_name'] Field to Entity
          EntityField.select_or_insert(entity_id, field_row['field_name'])
    end
    
  end
  
  #
  # "entitytype" command help
  #
  def cmd_entitytype_help(*args)
    print_status("Command    : entitytype")
    print_status("Description: assign the current entity an entitytype.")
    print_status("Usage      : 'entitytype <type_name>'")
  end
  
  
end # End Class
  
end end end  # End Modules