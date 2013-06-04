module Rubix

  class TemplateBuilder

    def to_xml
      Nokogiri::XML::Builder.new do |xml|
        xml.zabbix_export do
          xml.version version
          xml.date    created_at.iso8851

          # These are the host groups that need to be created to
          # support the rest of the content of this XML.  Typically,
          # this just contains a single host group "Templates" used
          # for the templates defined below.
          xml.groups do
            host_groups.each { |host_group| insert_xml_of(host_group) }
          end

          # These are templates.
          xml.templates do
            xml.template do
              xml.template name
              xml.name     name

              # These are the groups this template belongs to.  They
              # should also be named in the 'groups' node outside the
              # containing 'templates' node.
              xml.groups do
                host_groups.each { |host_group| insert_xml_of(host_group) }
              end

              # These are the applications this template defines.
              xml.applications do
                applications.each { |application| insert_xml_of(application) }
              end

              # These are the items this template defines.
              xml.items do
                items.each { |item| insert_xml_of(item) }
              end
              
              xml.templates do
                templates.each { |template| insert_xml_of(template) }
              end

              xml.screens do
              end
            end
          end

          xml.triggers do
            triggers.each { |trigger| insert_xml_of(trigger) }
          end

          xml.graphs do
          end
          
        end
      end
    end
    
  end
  
end
