module Redcap2omop
  class RedcapVariableMapsController < ApplicationController
    before_action :set_redcap_variable_map, only: %i[ show edit update destroy ]

    # GET /redcap_variable_maps or /redcap_variable_maps.json
    def index
      @redcap_variable_maps = RedcapVariableMap.all
    end

    # GET /redcap_variable_maps/1 or /redcap_variable_maps/1.json
    def show
    end

    # GET /redcap_variable_maps/new
    def new
      @redcap_variable_map = RedcapVariableMap.new
    end

    # GET /redcap_variable_maps/1/edit
    def edit
    end

    # POST /redcap_variable_maps or /redcap_variable_maps.json
    def create
      @redcap_variable_map = RedcapVariableMap.new(redcap_variable_map_params)

      respond_to do |format|
        if @redcap_variable_map.save
          format.html { redirect_to @redcap_variable_map, notice: "RedcapVariableMap was successfully created." }
          format.json { render :show, status: :created, location: @redcap_variable_map }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @redcap_variable_map.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /redcap_variable_maps/1 or /redcap_variable_maps/1.json
    def update
      respond_to do |format|
        if @redcap_variable_map.update(redcap_variable_map_params)
          format.html { redirect_to @redcap_variable_map, notice: "RedcapVariableMap was successfully updated." }
          format.json { render :show, status: :ok, location: @redcap_variable_map }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @redcap_variable_map.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /redcap_variable_maps/1 or /redcap_variable_maps/1.json
    def destroy
      @redcap_variable_map.destroy
      respond_to do |format|
        format.html { redirect_to redcap_variable_maps_url, notice: "RedcapVariableMap was successfully destroyed." }
        format.json { head :no_content }
      end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_redcap_variable_map
      @redcap_variable_map = RedcapVariableMap.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def redcap_variable_map_params
      params.fetch(:redcap_variable_map, {})
    end
  end

end
