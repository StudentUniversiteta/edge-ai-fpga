`timescale 1ns/1ps

module tb_cats_dogs;

    localparam int DW        = 16;
    localparam int ACCW      = 32;
    localparam int FRAC_BITS = 7;
    localparam int IN_SIZE   = 64;
    localparam int N_SAMPLES = 5; // Количество тестовых картинок

    logic clk = 0;
    logic rst = 1;
    logic start = 0;
    logic done;

    logic signed [DW-1:0] x0 [IN_SIZE]; // Вход
    logic output_class;                 // Результат (0 или 1)
    logic signed [DW-1:0] raw_logit;

    logic expected_label [N_SAMPLES];   // Правильные ответы

    integer i, correct_cnt = 0;

    // Генерация Clock
    always #5 clk = ~clk;

    // Подключение нейросети
    cats_dogs_top dut (
        .clk(clk), .rst(rst), .start(start),
        .x0(x0),
        .done(done),
        .output_class(output_class),
        .raw_logit(raw_logit)
    );

    // Загрузка правильных ответов
    initial begin
        // Здесь должен быть файл с ответами (0 или 1 на каждой строке)
        $readmemh("labels.hex", expected_label); 
    end

    initial begin
        $display("===== START SIMULATION =====");
        
        rst = 1; repeat(10) @(posedge clk);
        rst = 0;

        for (i = 0; i < N_SAMPLES; i++) begin
            string fname;
            fname = $sformatf("img%0d.hex", i); // Ищет файлы img0.hex, img1.hex...
            
            $display("Testing file: %s", fname);
            $readmemh(fname, x0); // Читаем картинку

            @(negedge clk); start = 1;
            @(negedge clk); start = 0;

            @(posedge done); // Ждем окончания работы нейросети
            repeat(2) @(posedge clk);

            $display("Output: %s | Expected: %s | Raw: %d", 
                     (output_class ? "DOG" : "CAT"), 
                     (expected_label[i] ? "DOG" : "CAT"),
                     raw_logit);

            if (output_class == expected_label[i]) correct_cnt++;
            else $display("--> MISMATCH!");
            
            repeat(10) @(posedge clk);
        end

        $display("Accuracy: %0d / %0d", correct_cnt, N_SAMPLES);
        $finish;
    end
endmodule