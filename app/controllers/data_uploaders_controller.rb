class DataUploadersController < ApplicationController
  respond_to :html

  def file_upload

  end

  def import
    if params[:file] then
      count_table_name = UserFileMapping.where('table_name LIKE ? OR table_name LIKE ?', "#{(params[:file].original_filename.split('.').first).tr(" ","")}%", "#{(params[:file].original_filename.split('.').first.pluralize).tr(" ","")}%").count
      table_name = count_table_name > 0? params[:file].original_filename.split('.').first + "#{count_table_name}" : params[:file].original_filename.split('.').first
      table_name = table_name.tr(" ","").gsub(/[^0-9A-Za-z]/, '')
      add_file_detail = UserFileMapping.insert_uploaded_file_record(current_user, params[:file].original_filename, table_name.downcase.pluralize)
      if add_file_detail.errors.any?
        errors = ""
        add_file_detail.errors.full_messages.each do |message|
          errors = errors + message + "\n"
        end
        redirect_to fileupload_datauploaders_path, :flash => { :error => errors }
      else
        csv_data = []
        CSV.foreach(params[:file].path) do |row|
          csv_data.append(row.to_a)
        end
        i = 0
        column_name = ''
        @columns_detail = []
        columns = csv_data.shift

        if columns.size != columns.uniq.size  then
          redirect_to fileupload_datauploaders_path, :flash => { :error => 'In uploaded file columns are repeated' }
        else
          csv_data = csv_data.transpose
          columns.each do |column|
            j = i+1;
            if column == nil then
              column = 'column' + j.to_s;
            else
              column = column.strip
              column = column.tr(' ', '')

              column = column.downcase

              if ((column == "null") || (column == "nil") || (column == "")) then
                column = "column" + j.to_s;
              end
              column.gsub(/[^0-9A-Za-z]/, '')
            end
            column_detail = {column_name: column,
                            is_nullable: false,
                            data_type: "",
                            date_format:"",
                            field_length: "0",
                            money_symbol: "",
                            is_money_format: false,
                            money_symbol_position: "",
                            is_unique: true}

            #trim blank spaces at beginning and end
            csv_data[i] = csv_data[i].collect{|x| if (x!=nil) then x.strip end}

            # check column contain more than 1 value of nil and blank
            if ((csv_data[i].count(nil) > 1) || (csv_data[i].count("") > 1)) then
              column_detail[:is_unique] = false
            end

            if ((csv_data[i].count(nil) > 0) || (csv_data[i].count("") > 0)) then
              column_detail[:is_nullable] = true
            end

            #removing blank, null and nil values from array
            csv_data[i] = csv_data[i].reject { |c| c.blank? }
            # convert in downcase each value of array
            csv_data[i] = csv_data[i].map(&:downcase)

            if ((csv_data[i].count("null") > 1) && (column_detail[:is_unique] == true))then
              column_detail[:is_unique] = false
            end

            if ((csv_data[i].count("null") > 0) || (csv_data[i].count("nil") > 0)) then
              column_detail[:is_nullable] = true
              if ((csv_data[i].include? 'null') == true) then
                csv_data[i].delete("null")
              end
              if ((csv_data[i].include? 'nil') == true) then
                csv_data[i].delete("nil")
              end
            end

            if column_detail[:is_unique] then
              if csv_data[i].size == csv_data[i].uniq.size  then
                column_detail[:is_unique] = true
              else
                column_detail[:is_unique] = false
              end
            end

            if csv_data[i].size == 0 then
              column_detail[:data_type] = "string"
              column_detail[:field_length] = "10"
            else
              if csv_data[i].size > 0 then
                bool_arr = ['true', '1', 'yes', 'on', 'false', '0', 'no', 'off', 0, 1]

                # Check array containing integer values only
                if column_detail[:data_type]=="" then
                  begin
                    if (csv_data[i] - bool_arr).empty? then
                      column_detail[:data_type] = "boolean"
                    end
                  rescue
                    # catch code at here
                  end
                end

                is_datetime = false
                input_field_splitter_used = ''
                if (((csv_data[i].collect{|v| v.include? '-'}).uniq).include? false)== false then
                  input_field_splitter_used = '-'
                  is_datetime = true
                end

                if (((csv_data[i].collect{|v| v.include? '/'}).uniq).include? false) == false then
                  input_field_splitter_used = '/'
                  is_datetime = true
                end

                if is_datetime then
                  temp_arr = csv_data[i].collect{|x| x.tr("-/", ' ')}
                  # Check array containing date values only
                  if column_detail[:data_type] == "" then
                    begin
                      is_data_integer=temp_arr.collect{|val| Date.strptime(val, "%m %d %Y")}
                      column_detail[:data_type] = "datetime"
                      column_detail[:date_format] = "%m" + input_field_splitter_used + "%d" + input_field_splitter_used + "%Y"
                    rescue
                      # catch code at here
                    end
                  end

                  # Check array containing date values only
                  if column_detail[:data_type] == "" then
                    begin
                      is_data_integer=temp_arr.collect{|val| Date.strptime(val, "%d %m %Y")}
                      column_detail[:data_type] = "datetime"
                      column_detail[:date_format] = "%d" + input_field_splitter_used + "%m" + input_field_splitter_used + "%Y"
                    rescue
                      # catch code at here
                    end
                  end

                  # Check array containing date values only
                  if column_detail[:data_type] == "" then
                    begin
                      is_data_integer=temp_arr.collect{|val| Date.strptime(val, "%Y %m %d")}
                      column_detail[:data_type] = "datetime"
                      column_detail[:date_format]="%Y" + input_field_splitter_used +  "%m" + input_field_splitter_used + "%d"
                    rescue
                      # catch code at here
                    end
                  end

                  # Check array containing date values only
                  if column_detail[:data_type] == "" then
                    begin
                      is_data_integer=temp_arr.collect{|val| Date.strptime(val, "%Y %d %m")}
                      column_detail[:data_type] = "datetime"
                      column_detail[:date_format] = "%Y" + input_field_splitter_used +  "%d" + input_field_splitter_used + "%m"
                    rescue
                      # catch code at here
                    end
                  end

                  # Check array containing date values only
                  if column_detail[:data_type] == "" then
                    begin
                      is_data_integer=csv_data[i].collect{|val| DateTime.parse(val)}
                      column_detail[:data_type] = "datetime"
                    rescue
                      # catch code at here
                    end
                  end
                end

                # Check array containing integer values only
                if column_detail[:data_type]=="" then
                  begin
                    is_data_integer=csv_data[i].collect{|val| Integer(val)}
                    column_detail[:data_type] = "integer"
                  rescue
                    # catch code at here
                  end
                end

                # check array containing money format
                if column_detail[:data_type]=="" then
                  begin
                    money_symbol = ''
                    symbol_length = 0
                    #byebug
                    money_symbols = ['$','€','£','¥','Fr','kr','zł','Ft','Kč','A$','R$','RM','₱','NT$','฿', 'TRY', '₹']
                    money_symbols.each do |symbol|
                      symbol_length = symbol.size

                      if (csv_data[i].collect{|k| k[0...symbol_length]}.uniq)[0] == symbol then
                        money_symbol = symbol
                        column_detail[:is_money_format] = true
                        column_detail[:money_symbol_position] = "start"
                        break
                      end
                      if (csv_data[i].collect{|k| k[(k.size-symbol_length)...k.size]}.uniq)[0] == symbol then
                        money_symbol = symbol
                        column_detail[:is_money_format] = true
                        column_detail[:money_symbol_position] = "end"
                        break
                      end
                    end

                    if money_symbol != '' then
                      temp_arr = csv_data[i].collect{|x| x.tr(money_symbol, '').strip}
                      is_data_integer=temp_arr.collect{|val| Float(val.gsub(/,/,''))}
                      max_length_after_decimal = (((temp_arr.map{|k| k.split('.')[1]}).reject { |c| c.blank? }).group_by(&:size).max.last)[0].size
                      maxL_length_before_decimal = (((temp_arr.map{|k| k.split('.')[0]}).reject { |c| c.blank? }).group_by(&:size).max.last)[0].size
                      column_detail[:field_length] = (maxL_length_before_decimal + max_length_after_decimal + 1).to_s + "," + max_length_after_decimal.to_s
                      column_detail[:data_type] = "decimal"
                      column_detail[:money_symbol] = money_symbol
                    end
                  rescue
                    # catch code at here
                  end
                end

                # Check array containing float values only
                if column_detail[:data_type]=="" then
                  begin
                    is_data_integer=csv_data[i].collect{|val| Float(val)}
                    max_length_after_decimal = (((csv_data[i].map{|k| k.split('.')[1]}).reject { |c| c.blank? }).group_by(&:size).max.last)[0].size
                    maxL_length_before_decimal = (((csv_data[i].map{|k| k.split('.')[0]}).reject { |c| c.blank? }).group_by(&:size).max.last)[0].size
                    column_detail[:field_length] = (maxL_length_before_decimal + max_length_after_decimal + 1).to_s + "," + max_length_after_decimal.to_s
                    column_detail[:data_type] = "decimal"
                  rescue
                    # catch code at here
                  end
                end

                # Check array containing string values
                if column_detail[:data_type]=="" then
                  begin
                    is_data_integer=csv_data[i].collect{|val| String(val)}
                    column_detail[:data_type] = "string"
                  rescue
                    # catch code at here
                  end
                end
                if column_detail[:data_type]!= 'decimal' then
                  column_detail[:field_length] = ((csv_data[i].group_by(&:size).max.last)[0].size) + 1
                end
              end
            end
            @columns_detail.append(column_detail)
            i=i+1
          end
          is_table_created = DataUploader.create_dynamic_table(table_name.downcase.pluralize, @columns_detail)
          if is_table_created
            begin
              @columns_detail.each do |column|
                if column[:is_money_format]==true
                  update_column_info=UserTableColumnInformation.create(
                      table_name: table_name.downcase.pluralize,
                      column_name: column[:column_name],
                      money_format:  column[:money_symbol],
                      is_disable: false,
                      created_by: current_user.id,
                      created_on: Time.now ,
                      modified_by: current_user.id,
                      modified_on: Time.now)
                end
              end
            rescue
            end
            DataUploader.insert_csv_data(params[:file].path, table_name.downcase.pluralize, @columns_detail)
            redirect_to showuploadedschema_datauploaders_path({:table_name => table_name.downcase.pluralize}), notice: "Data Uploaded Successfully"
          else
            redirect_to fileupload_datauploaders_path, :flash => { :error => "Error: #{is_table_created}" }
          end
        end
      end
    else
      redirect_to fileupload_datauploaders_path, :flash => { :error => "Please select a file to upload data." }
    end
  end

  # show upload csv generated table schema
  def show_uploaded_schema
    @table_name = params[:table_name]
    @uploaded_schema = DataUploader.get_uploaded_schema(@table_name)
    if @uploaded_schema.size>0
      @disabled_column = get_user_table_column_info(@table_name)
    else
      redirect_to uploadedfile_datauploaders_path, :flash => { :error => "Table schema not exists" }
    end
  end

  # find uploaded files details
  def uploaded_file
    currentUser = current_user.id
    @uploadedFiles = UserFileMapping.where(:user_id =>currentUser )
    respond_with(@uploadedFiles)
  end

  # find uploaded file records
  def upload_file_record
    @table_record={columns:[], records:[] }
    @uploaded_records=[]
    table_name = params[:table_name]
    @uploadedSchema = DataUploader.get_uploaded_schema(table_name)
    if @uploadedSchema.size>0
      response = DataUploader.get_table_data(table_name)
      if response.size > 0 then
        disabled_column = get_user_table_column_info(table_name)
        @uploadedSchema.each do |schema|
          @table_record[:columns].append({column_name: schema[:Field],is_disable: (disabled_column.include?schema[:Field]) })
        end
        response.each do |record|
          @table_record[:records].append(record)
        end
      end
      respond_with(@uploaded_records,@uploadedSchema,@table_record)
    else
      redirect_to uploadedfile_datauploaders_path, :flash => { :error => "Table schema does not exists" }
    end

  end

  def change_table_column_detail
    @uploaded_records=[]
    respond_with(@uploaded_records)
  end

  def column_exclude_include
    table_name = params[:table_name]
    column_name = params[:column_name]
    is_column_disabled = params[:is_column_disabled]
    errors = ""
    update_column_info = UserTableColumnInformation.update_column_information(current_user, is_column_disabled, table_name, column_name)
    if update_column_info.errors.any?
      update_column_info.errors.full_messages.each do |message|
        errors = errors + message + "\n"
      end
    end
    respond_to do |format|
      format.html { redirect_to showuploadedschema_datauploaders_path({:table_name => table_name}), notice: (errors.size ==0 ? "Column detail update Successfully":errors)  }
      format.json { head :no_content }
    end
  end
end