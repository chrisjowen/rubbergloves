defmodule Rubbergloves.Crud do
  alias Rubbergloves.Crud

  defmacro __using__(repo: repo) do
    quote do
      alias Rubbergloves.Crud
      import Rubbergloves.Crud
      @repo unquote(repo)
    end
  end

  defmacro defcreate(module) do
    name = module_name(module)
    quote do
      def unquote(:"create_#{name}")(attrs \\ %{}) do
        %unquote(module){}
        |> unquote(module).changeset(attrs)
        |> @repo.insert()
      end
    end
  end

  defmacro defupdate(module) do
    name = module_name(module)
    quote do
      def unquote(:"update_#{name}")(item = %unquote(module){}, attrs \\ %{}) do
        item
        |> unquote(module).changeset(attrs)
        |> @repo.update()
      end
    end
  end

  defmacro defread(module) do
    name = module_name(module)
    quote do
      def unquote(:"get_#{name}!")(id, preloads \\ []) do
        @repo.get!(unquote(module), id) |> @repo.preload(preloads)
      end
      def unquote(:"get_#{name}")(id, preloads \\ []) do
        with {:ok, release} <- @repo.get!(unquote(module), id) do
          {:ok, @repo.preload(release, preloads)}
        end
      end
    end
  end

  defmacro deflist(module) do
    name = module_name(module)
    quote do
      def unquote(:"list_#{name}s")(preloads \\ []) do
        @repo.all(unquote(module)) |> @repo.preload(preloads)
      end
    end
  end

  defmacro defdelete(module) do
    name = module_name(module)
    quote do
      def unquote(:"delete_#{name}")(item = %unquote(module){}) do
        @repo.delete(item)
      end
    end
  end

  defmacro defcrud(options) when is_list(options) do
    quote do
      Enum.map(unquote(options), &Crud.defcrud/1)
    end
  end

  defmacro defcrud({module, methods}) do
    quote do
      defcrud(unquote(module), unquote(methods))
    end
  end

  defmacro defcrud(module, methods \\ [:create, :read, :update, :delete, :list]) do
    quote do
      if(Enum.member?(unquote(methods), :create)) do
        defcreate(unquote(module))
      end

      if(Enum.member?(unquote(methods), :read)) do
        defread(unquote(module))
      end

      if(Enum.member?(unquote(methods), :update)) do
        defupdate(unquote(module))
      end

      if(Enum.member?(unquote(methods), :delete)) do
        defdelete(unquote(module))
      end

      if(Enum.member?(unquote(methods), :list)) do
        deflist(unquote(module))
      end
    end
  end

  defp module_name({_, _, [:Schema, module_atom]}) do
    module_atom
    |> Atom.to_string()
    |> Macro.underscore()
  end

end
