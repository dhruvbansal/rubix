module Rubix
  
  class Inventory < Model
    
    FIELDS = %w[asset_tag chassis contact contract_number date_hw_decomm date_hw_expiry date_hw_install
 date_hw_purchase deployment_status hardware hardware_full host_netmask host_networks
 host_router hw_arch installer_name location location_lat location_lon
 macaddress_a macaddress_b model name oob_ip oob_netmask oob_router os os_full os_short
 poc_1_cell poc_1_email poc_1_name poc_1_notes poc_1_phone_a poc_1_phone_b poc_1_screen
 poc_2_cell poc_2_email poc_2_name poc_2_notes poc_2_phone_a poc_2_phone_b poc_2_screen
 serialno_a serialno_b site_address_a site_address_b site_address_c site_city site_country
 site_notes site_rack site_state site_zip software software_app_a software_app_b software_app_c
 software_app_d software_app_e software_full tag type type_full url_a url_b url_c vendor]
    
    FIELDS.each { |attr_name| zabbix_attr attr_name }

    zabbix_define :MODE, {
      :disabled  => -1,
      :manual    =>  0,
      :automatic =>  1
    }
    zabbix_attr :mode, :default => :manual

    def initialize properties={}
      super(properties)
      self.host_id       = properties[:host_id]
      self.host          = properties[:host]
    end

    #
    # == Associations ==
    #

    include Associations::BelongsToHost
    
    #
    # == Requests ==
    #
    
    def create_params
      {}.tap do |cp|
        FIELDS.each do |field|
          cp[field.to_sym] = self.send(field)
        end
        cp[:inventory_mode] = self.class::MODE_CODES[type]
      end
    end

    def self.build inventory
      new(inventory.dup.tap { |i| i['mode'] = self::MODE_NAMES[i.delete('inventory_mode').to_i] })
    end
    
  end
end
