function Reviews() {
  return (
    <div className="bg-white  sm:py-10">
      <div className="mx-auto text-center ">
        <h2 className="text-center text-lg font-semibold leading-8 text-gray-900">
          Empresas que confían en nosotros
        </h2>
        <div className="mx-auto mt-10 grid max-w-lg grid-cols-4 items-center gap-x-8 gap-y-10 sm:max-w-xl sm:grid-cols-6 sm:gap-x-10 lg:mx-0 lg:max-w-none lg:grid-cols-3">
          <img
            className="col-span-2 max-h-12 w-full object-contain lg:col-span-1 mx-auto"
            src="https://static.vecteezy.com/system/resources/thumbnails/053/382/798/small/the-logo-for-a-company-that-makes-colorful-abstract-shapes-free-png.png"
            alt="Transistor"
            width="158"
            height="48"
          />

          <img
            className="col-span-2 max-h-12 w-full object-contain lg:col-span-1 mx-auto"
            src="https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Logo_Biob%C3%ADo_Chile.png/1280px-Logo_Biob%C3%ADo_Chile.png"
            alt="Tuple"
            width="158"
            height="48"
          />
          <img
            className="col-span-2 max-h-12 w-full object-contain sm:col-start-2 lg:col-span-1 mx-auto"
            src="https://images.vexels.com/media/users/3/142887/isolated/preview/fc58c5ffb8c2e33fc3e15a2453189825-logotipo-de-empresa-logistica-en-crecimiento.png"
            alt="SavvyCal"
            width="158"
            height="48"
          />
        </div>
      </div>
    </div>
  );
}

export default Reviews;
