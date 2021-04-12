module Redcap2omop
  class RedcapVariableMapsController < ApplicationController
    before_action :set_redcap_variable_map, only: %i[ show edit update destroy ]

    # GET /redcap_variable_maps or /redcap_variable_maps.json
    def index
      @redcap2omop_redcap_variable_maps = Redcap2omop::RedcapVariableMap.all
      @redcap2omop_redcap_variable_map = Redcap2omop::RedcapVariableMap.new
    end

    # GET /redcap_variable_maps/1 or /redcap_variable_maps/1.json
    def show
    end

    # GET /redcap_variable_maps/new
    def new
      @redcap2omop_redcap_variable_map = Redcap2omop::RedcapVariableMap.new
    end

    # GET /redcap_variable_maps/1/edit
    def edit
    end

    # POST /redcap_variable_maps or /redcap_variable_maps.json
    def create
      @redcap2omop_redcap_variable_map = Redcap2omop::RedcapVariableMap.new(redcap_variable_map_params)

      respond_to do |format|
        if @redcap2omop_redcap_variable_map.save
          format.html { redirect_to redcap_variable_maps_url }
          format.json { render :show, status: :created, location: @redcap2omop_redcap_variable_map }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @redcap2omop_redcap_variable_map.errors, status: :unprocessable_entity }
          format.turbo_stream { render turbo_stream: turbo_stream.replace(@redcap2omop_redcap_variable_map, partial: 'redcap2omop/redcap_variable_maps/form', locals: { redcap2omop_redcap_variable_map: @redcap2omop_redcap_variable_map }) } ## New for this article
        end
      end
    end

    # PATCH/PUT /redcap_variable_maps/1 or /redcap_variable_maps/1.json
    def update
      respond_to do |format|
        if @redcap2omop_redcap_variable_map.update(redcap_variable_map_params)
          format.html { redirect_to redcap_variable_maps_url }
          format.json { render :show, status: :ok, location: @redcap2omop_redcap_variable_map }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @redcap2omop_redcap_variable_map.errors, status: :unprocessable_entity }
          format.turbo_stream { render turbo_stream: turbo_stream.replace(@redcap2omop_redcap_variable_map, partial: 'redcap2omop/redcap_variable_maps/form', locals: { redcap2omop_redcap_variable_map: @redcap2omop_redcap_variable_map }) } ## New for this article
        end
      end
    end

    # DELETE /redcap_variable_maps/1 or /redcap_variable_maps/1.json
    def destroy
      @redcap2omop_redcap_variable_map.destroy
      respond_to do |format|
        format.html { redirect_to redcap_variable_maps_url, notice: "RedcapVariableMap was successfully destroyed." }
        format.json { head :no_content }
      end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_redcap_variable_map
      @redcap2omop_redcap_variable_map = Redcap2omop::RedcapVariableMap.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def redcap_variable_map_params
      params.require(:redcap_variable_map).permit(:redcap_variable_id, :map_type)
    end
  end

end
