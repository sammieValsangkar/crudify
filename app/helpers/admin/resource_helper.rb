module Admin::ResourceHelper
  def foreign_key_on()

  end

  def dropdown_options_for_foreign_key(klass, attrib)
    foreign_klass = get_klass_for_foreign_key(klass, attrib)
    get_collection(foreign_klass)
  end

  def display_dynamic_relation(object, attrib)
    foreign_klass = get_klass_for_foreign_key(object.class, attrib)
    o = foreign_klass.find_by_id(object.send(attrib))
    o.name.to_s.titleize if o
  end

  def get_klass_for_foreign_key(klass, attrib)
    klass.reflect_on_all_associations(:belongs_to)
         .select { |a| a.foreign_key == attrib }
         .first.klass
  end

  def get_collection(klass)
    klass.all.map { |v| ["#{v.try(:name)}".titleize , v.id] }
  end

  def presence_validator_present?(klass, col_name)
    klass.validators_on(col_name.to_sym).any? do |mem|
      mem.is_a? ActiveRecord::Validations::PresenceValidator
    end
  end

  def l_datetime(date)
    return '' if date.nil?

    date.strftime('%d %b %Y %I:%M %p')
  end

end