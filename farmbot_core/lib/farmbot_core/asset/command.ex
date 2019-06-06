defmodule FarmbotCore.Asset.Command do
  @moduledoc """
  A collection of functions that _write_ to the DB
  """
  alias FarmbotCore.{Asset, Asset.Repo}
  alias Asset.FarmEvent

  @typedoc "String kind that should be turned into an Elixir module."
  @type kind :: String.t()

  @typedoc "key/value map of changes"
  @type params :: map()

  @typedoc "remote database id"
  @type id :: integer()

  @doc """
  Will insert, update or delete data in the local database.
  This function will raise if error occur.
  """
  @callback update(kind, params, id) :: :ok | no_return()

  def update("Device", params) do 
    Asset.update_device!(params)
    :ok
  end
  
  def update("FbosConfig", params, _) do 
    Asset.update_fbos_config!(params)
    :ok
  end
  
  def update("FirmwareConfig", params, _) do 
    Asset.update_firmware_config!(params)
    :ok
  end
  
  def update("FarmwareEnv", params, id) do 
    Asset.upsert_farmware_env_by_id(id, params)
    :ok
  end
  
  def update("FarmwareInstallation", id, params) do 
    Asset.upsert_farmware_env_by_id(id, params)
    :ok
  end

  def update("FarmEvent", id, params) do
    old = Asset.get_farm_event(id) || struct!(FarmEvent)
    Asset.update_farm_event!(old, params)
  end

  # Deletion use case:
  def update(asset_kind, nil, id) do
    old = Repo.get_by(as_module!(asset_kind), id: id)
    old && Repo.delete!(old)
    :ok
  end

  # Catch-all use case:
  def update(asset_kind, params, id) do
    mod = as_module!(asset_kind)
    case Repo.get_by(mod, id: id) do
      nil ->
        struct!(mod)
        |> mod.changeset(params)
        |> Repo.insert!()

      asset ->
        mod.changeset(asset, params)
        |> Repo.update!()
    end

    :ok
  end

  @doc "Returns a Ecto Changeset that can be cached or applied."
  @callback new_changeset(kind, id, params) :: Ecto.Changeset.t()
  def new_changeset(asset_kind, id, params) do
    mod = as_module!(asset_kind)
    asset = Repo.get_by(mod, id: id) || struct!(mod)
    mod.changeset(asset, params)
  end

  defp as_module!("Device"), do: Asset.Device 
  defp as_module!("DiagnosticDump"), do: Asset.DiagnosticDump 
  defp as_module!("FarmEvent"), do: Asset.FarmEvent 
  defp as_module!("FarmwareEnv"), do: Asset.FarmwareEnv 
  defp as_module!("FarmwareInstallation"), do: Asset.FarmwareInstallation 
  defp as_module!("FbosConfig"), do: Asset.FbosConfig 
  defp as_module!("FirmwareConfig"), do: Asset.FirmwareConfig 
  defp as_module!("Peripheral"), do: Asset.Peripheral 
  defp as_module!("PinBinding"), do: Asset.PinBinding 
  defp as_module!("Point"), do: Asset.Point 
  defp as_module!("Regimen"), do: Asset.Regimen 
  defp as_module!("Sensor"), do: Asset.Sensor 
  defp as_module!("Sequence"), do: Asset.Sequence 
  defp as_module!("Tool"), do: Asset.Tool 
  defp as_module!(kind) when is_binary(kind) do
    raise("""
    Unknown kind: #{kind}
    """)
  end
end
