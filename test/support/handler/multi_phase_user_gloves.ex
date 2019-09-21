defmodule MultiPhaseUserGloves do
  use Rubbergloves.Handler, wearer: RubberglovesTest.User

  can_handle?(_everyone, :anything) do
    :ok
  end

  phase :before do
    can_handle?(_everyone, :anything, nil) do
      :ok
    end

    can_handle?(_everyone, :handled_later, nil) do
      {:error, :handled_later}
    end
  end

  phase :after do
    can_handle!(_everyone, :handled_later)
  end
end
